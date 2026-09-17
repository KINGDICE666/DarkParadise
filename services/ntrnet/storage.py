import json
import os
import re
import shutil
import subprocess
import tempfile
from pathlib import Path


IMAGE_LIMIT = 10 * 1024 * 1024
VIDEO_LIMIT = 30 * 1024 * 1024
SITE_LIMIT = 50 * 1024 * 1024
MEDIA_ORIGIN = 'https://media.wiki-ss13.space'
OBJECT_KEY = re.compile(r'[a-f0-9]{32}/[a-f0-9]{16}\.(?:png|gif|jpg|webp|mp4)\Z')
KINDS = {
    b'\x89PNG\r\n\x1a\n': ('image/png', '.png'),
    b'GIF87a': ('image/gif', '.gif'),
    b'GIF89a': ('image/gif', '.gif'),
    b'\xff\xd8\xff': ('image/jpeg', '.jpg'),
}


class MediaError(ValueError):
    pass


def inspect_upload(upload):
    filename = (upload.filename or '').strip()
    if not filename or len(filename) > 160:
        raise MediaError('У файла нет имени или оно слишком длинное.')
    if any(ord(character) < 32 for character in filename):
        raise MediaError('Имя файла содержит недопустимые символы.')
    upload.stream.seek(0, os.SEEK_END)
    size = upload.stream.tell()
    upload.stream.seek(0)
    header = upload.stream.read(16)
    upload.stream.seek(0)
    if header[8:12] == b'WEBP' and header[:4] == b'RIFF':
        content_type, extension = 'image/webp', '.webp'
    else:
        match = next((value for magic, value in KINDS.items() if header.startswith(magic)), None)
        if match:
            content_type, extension = match
        elif header[4:8] == b'ftyp':
            content_type, extension = 'video/mp4', '.mp4'
        else:
            raise MediaError('Разрешены PNG, JPEG, GIF, WebP и MP4.')
    limit = VIDEO_LIMIT if content_type == 'video/mp4' else IMAGE_LIMIT
    if size < 1 or size > limit:
        raise MediaError(f'Размер файла должен быть от 1 байта до {limit // (1024 * 1024)} МБ.')
    if content_type == 'video/mp4':
        validate_video(upload.stream)
    else:
        validate_image(upload.stream, content_type)
    return filename, content_type, extension, size


def validate_image(stream, content_type):
    from PIL import Image, UnidentifiedImageError
    expected = {'image/png': 'PNG', 'image/gif': 'GIF', 'image/jpeg': 'JPEG', 'image/webp': 'WEBP'}[content_type]
    Image.MAX_IMAGE_PIXELS = 4096 * 4096
    try:
        image = Image.open(stream)
        if image.format != expected or image.width > 4096 or image.height > 4096 or image.width * image.height > 4096 * 4096:
            raise MediaError('Изображение должно быть не больше 4096×4096 пикселей.')
        if getattr(image, 'n_frames', 1) > 300:
            raise MediaError('В анимации должно быть не больше 300 кадров.')
        image.verify()
    except (UnidentifiedImageError, OSError, SyntaxError) as error:
        raise MediaError('Файл изображения повреждён.') from error
    finally:
        stream.seek(0)


def validate_video(stream):
    ffprobe = os.environ.get('NTRNET_FFPROBE', 'ffprobe')
    with tempfile.NamedTemporaryFile(suffix='.mp4') as temporary:
        while chunk := stream.read(1024 * 1024):
            temporary.write(chunk)
        temporary.flush()
        stream.seek(0)
        try:
            result = subprocess.run([
                ffprobe, '-v', 'error', '-show_entries', 'format=format_name:stream=codec_type,codec_name',
                '-of', 'json', temporary.name,
            ], capture_output=True, text=True, timeout=12, check=True)
            document = json.loads(result.stdout)
        except (FileNotFoundError, subprocess.SubprocessError, json.JSONDecodeError) as error:
            raise MediaError('Не удалось проверить MP4 через ffprobe.') from error
    if 'mp4' not in document.get('format', {}).get('format_name', '').split(','):
        raise MediaError('Видео должно быть контейнером MP4.')
    streams = document.get('streams', [])
    videos = [stream for stream in streams if stream.get('codec_type') == 'video']
    audios = [stream for stream in streams if stream.get('codec_type') == 'audio']
    if len(videos) != 1 or videos[0].get('codec_name') != 'h264':
        raise MediaError('Видео должно использовать кодек H.264.')
    if any(stream.get('codec_name') != 'aac' for stream in audios):
        raise MediaError('Звуковая дорожка должна использовать кодек AAC.')


class LocalMediaStore:
    def __init__(self):
        configured_root = os.environ.get('NTRNET_MEDIA_ROOT', '')
        self.public_url = os.environ.get('NTRNET_MEDIA_URL', MEDIA_ORIGIN).rstrip('/')
        if self.public_url != MEDIA_ORIGIN:
            raise ValueError(f'NTRNET_MEDIA_URL must be {MEDIA_ORIGIN}')
        self.enabled = bool(configured_root)
        configured_path = Path(configured_root) if configured_root else None
        if configured_path is not None and not configured_path.is_absolute():
            raise ValueError('NTRNET_MEDIA_ROOT must be an absolute path')
        self.root = configured_path.resolve() if configured_path is not None else None

    def _path(self, object_key):
        if not self.enabled:
            raise MediaError('Локальное хранилище медиа ещё не настроено.')
        if not OBJECT_KEY.fullmatch(object_key):
            raise MediaError('Недопустимый ключ медиафайла.')
        return self.root.joinpath(*object_key.split('/'))

    def url(self, object_key):
        return self.public_url + '/' + object_key

    def upload(self, stream, object_key, content_type):
        target = self._path(object_key)
        temporary_path = None
        stream.seek(0)
        try:
            target.parent.mkdir(mode=0o755, parents=True, exist_ok=True)
            os.chmod(target.parent, 0o755)
            with tempfile.NamedTemporaryFile(dir=target.parent, delete=False) as temporary:
                temporary_path = Path(temporary.name)
                shutil.copyfileobj(stream, temporary)
                temporary.flush()
                os.fsync(temporary.fileno())
            os.chmod(temporary_path, 0o644)
            temporary_path.replace(target)
        except OSError as error:
            if temporary_path is not None:
                temporary_path.unlink(missing_ok=True)
            raise MediaError('Сервер не смог сохранить файл. Попробуйте позже.') from error
        finally:
            stream.seek(0)

    def delete(self, object_key):
        target = self._path(object_key)
        try:
            target.unlink(missing_ok=True)
            try:
                target.parent.rmdir()
            except OSError:
                pass
        except OSError as error:
            raise MediaError('Сервер не смог удалить файл. Попробуйте позже.') from error
