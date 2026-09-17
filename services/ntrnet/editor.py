import json
import re
import secrets
from urllib.parse import urlsplit

from flask import Blueprint, abort, g, make_response, redirect, render_template, request
from sqlalchemy import delete, func, insert, or_, select, update
from sqlalchemy.exc import IntegrityError

from content import ContentError, compile_page, render_tree
from database import media, now, pages, servers, sites, zones
from storage import MediaError, SITE_LIMIT, inspect_upload


SITE_NAME = re.compile(r'[a-zа-яё0-9](?:[a-zа-яё0-9-]{1,22}[a-zа-яё0-9])?\Z')
SLUG = re.compile(r'[a-z0-9](?:[a-z0-9-]{0,62}[a-z0-9])?\Z')
STARTER_HTML = '<h1>Новая страница</h1>\n<p>Начните писать здесь.</p>'
STARTER_CSS = 'h1 { color: #74e3bc; }'


def create_editor(identity, csrf_valid, csrf_cookie, media_store):
    editor = Blueprint('editor', __name__)

    def account():
        current = identity()
        if current is None:
            abort(401)
        return current

    def owner_site(site_id):
        current = account()
        record = g.db.execute(select(sites).where(
            sites.c.id == site_id, sites.c.owner_ckey == current['ckey'],
        )).mappings().first()
        if record is None:
            abort(404)
        return current, record

    def csrf():
        if not csrf_valid():
            abort(403)

    def token():
        value = request.cookies.get(csrf_cookie, '')
        if len(value) != 43:
            abort(403)
        return value

    def media_rows(site_id):
        records = g.db.execute(select(media).where(media.c.site_id == site_id)
                               .order_by(media.c.created_at, media.c.filename)).mappings().all()
        return [dict(record, url=media_store.url(record['object_key'])) for record in records]

    def lock_site(site_id):
        g.db.execute(select(sites.c.id).where(sites.c.id == site_id).with_for_update()).first()

    def page_form(current, site, page, error=None, status=200):
        return render_template('page.html', account=current, site=site, page=page,
                               media=media_rows(site['id']), csrf=token(), error=error), status

    @editor.post('/sites')
    def create_site():
        csrf()
        current = account()
        name = request.form.get('name', '').strip().lower()
        zone = request.form.get('zone', '').strip().lower()
        title = request.form.get('title', '').strip()
        latin = any('a' <= character <= 'z' for character in name)
        cyrillic = any('а' <= character <= 'я' or character == 'ё' for character in name)
        allowed_zone = g.db.execute(select(zones.c.name).where(
            zones.c.name == zone, zones.c.active.is_(True),
            or_(zones.c.server_id.is_(None), zones.c.server_id == current['server_id']),
        )).scalar_one_or_none()
        g.db.execute(select(servers.c.id).where(servers.c.id == current['server_id']).with_for_update()).first()
        count = g.db.execute(select(func.count()).select_from(sites).where(
            sites.c.owner_ckey == current['ckey'],
        )).scalar_one()
        if count >= 3:
            return redirect('/?error=limit', code=303)
        if not SITE_NAME.fullmatch(name) or latin and cyrillic or not 1 <= len(title) <= 160 or allowed_zone is None:
            return redirect('/?error=site', code=303)
        site_id = secrets.token_hex(16)
        tree = compile_page(STARTER_HTML, STARTER_CSS)
        try:
            g.db.execute(insert(sites).values(id=site_id, name=name, zone=zone,
                                              owner_ckey=current['ckey'], title=title, version=1,
                                              hidden=False, preview_token=secrets.token_urlsafe(32)))
            g.db.execute(insert(pages).values(site_id=site_id, slug='index', title='Главная', position=0,
                                              source_html=STARTER_HTML, source_css=STARTER_CSS,
                                              tree=json.dumps(tree, ensure_ascii=False, separators=(',', ':'))))
            g.db.commit()
        except IntegrityError:
            g.db.rollback()
            return redirect('/?error=domain', code=303)
        return redirect(f'/sites/{site_id}', code=303)

    @editor.get('/sites/<site_id>')
    def site_page(site_id):
        current, site = owner_site(site_id)
        page_rows = g.db.execute(select(pages.c.slug, pages.c.title, pages.c.position).where(
            pages.c.site_id == site_id,
        ).order_by(pages.c.position, pages.c.slug)).mappings().all()
        errors = {
            'delete': 'Для удаления введите полный адрес сайта.',
            'duplicate': 'Страница с таким адресом уже существует.',
            'media': 'Файл не принят. Проверьте формат, размер и свободное место на сервере.',
            'media-delete': 'Сервер не удалил файл. Попробуйте позже.',
            'media-used': 'Сначала уберите этот файл со всех страниц сайта.',
            'page': 'Проверьте название и короткий адрес страницы.',
            'pages': 'На сайте уже двадцать страниц.',
            'title': 'Название должно содержать от 1 до 160 символов.',
        }
        return render_template('site.html', account=current, site=site, pages=page_rows,
                               media=media_rows(site_id), csrf=token(), media_enabled=media_store.enabled,
                               error=errors.get(request.args.get('error')))

    @editor.post('/sites/<site_id>/settings')
    def site_settings(site_id):
        csrf()
        _current, site = owner_site(site_id)
        lock_site(site_id)
        title = request.form.get('title', '').strip()
        if not 1 <= len(title) <= 160:
            return redirect(f'/sites/{site_id}?error=title', code=303)
        g.db.execute(update(sites).where(sites.c.id == site['id'])
                     .values(title=title, version=sites.c.version + 1))
        g.db.commit()
        return redirect(f'/sites/{site_id}', code=303)

    @editor.post('/sites/<site_id>/preview-token')
    def rotate_preview(site_id):
        csrf()
        _current, site = owner_site(site_id)
        lock_site(site_id)
        g.db.execute(update(sites).where(sites.c.id == site['id'])
                     .values(preview_token=secrets.token_urlsafe(32)))
        g.db.commit()
        return redirect(f'/sites/{site_id}', code=303)

    @editor.post('/sites/<site_id>/pages')
    def create_page(site_id):
        csrf()
        _current, site = owner_site(site_id)
        lock_site(site_id)
        slug = request.form.get('slug', '').strip().lower()
        title = request.form.get('title', '').strip()
        count = g.db.execute(select(func.count()).select_from(pages).where(
            pages.c.site_id == site_id,
        )).scalar_one()
        if count >= 20:
            return redirect(f'/sites/{site_id}?error=pages', code=303)
        if not SLUG.fullmatch(slug) or not 1 <= len(title) <= 160:
            return redirect(f'/sites/{site_id}?error=page', code=303)
        position = g.db.execute(select(func.coalesce(func.max(pages.c.position), -1)).where(
            pages.c.site_id == site_id,
        )).scalar_one() + 1
        tree = compile_page(STARTER_HTML, STARTER_CSS)
        try:
            g.db.execute(insert(pages).values(site_id=site_id, slug=slug, title=title, position=position,
                                                  source_html=STARTER_HTML, source_css=STARTER_CSS,
                                                  tree=json.dumps(tree, ensure_ascii=False, separators=(',', ':'))))
            g.db.execute(update(sites).where(sites.c.id == site['id'])
                         .values(version=sites.c.version + 1))
            g.db.commit()
        except IntegrityError:
            g.db.rollback()
            return redirect(f'/sites/{site_id}?error=duplicate', code=303)
        return redirect(f'/sites/{site_id}/pages/{slug}', code=303)

    @editor.get('/sites/<site_id>/pages/<slug>')
    def edit_page(site_id, slug):
        current, site = owner_site(site_id)
        page = g.db.execute(select(pages).where(
            pages.c.site_id == site_id, pages.c.slug == slug,
        )).mappings().first()
        if page is None:
            abort(404)
        return page_form(current, site, page)

    @editor.post('/sites/<site_id>/pages/<slug>')
    def save_page(site_id, slug):
        csrf()
        current, site = owner_site(site_id)
        lock_site(site_id)
        page = g.db.execute(select(pages).where(
            pages.c.site_id == site_id, pages.c.slug == slug,
        )).mappings().first()
        if page is None:
            abort(404)
        title = request.form.get('title', '').strip()
        source_html = request.form.get('source_html', '')
        source_css = request.form.get('source_css', '')
        submitted = dict(page, title=title, source_html=source_html, source_css=source_css)
        if not 1 <= len(title) <= 160:
            return page_form(current, site, submitted, 'Название должно содержать от 1 до 160 символов.', 400)
        try:
            tree = compile_page(source_html, source_css, media_rows(site_id))
        except ContentError as error:
            return page_form(current, site, submitted, str(error), 400)
        g.db.execute(update(pages).where(pages.c.site_id == site_id, pages.c.slug == slug).values(
            title=title, source_html=source_html, source_css=source_css,
            tree=json.dumps(tree, ensure_ascii=False, separators=(',', ':')),
        ))
        g.db.execute(update(sites).where(sites.c.id == site['id'])
                     .values(version=sites.c.version + 1))
        g.db.commit()
        return redirect(f'/sites/{site_id}/pages/{slug}?saved=1', code=303)

    @editor.post('/sites/<site_id>/pages/<slug>/delete')
    def delete_page(site_id, slug):
        csrf()
        _current, site = owner_site(site_id)
        lock_site(site_id)
        if slug == 'index':
            abort(400)
        removed = g.db.execute(delete(pages).where(
            pages.c.site_id == site_id, pages.c.slug == slug,
        )).rowcount
        if not removed:
            abort(404)
        g.db.execute(update(sites).where(sites.c.id == site['id'])
                     .values(version=sites.c.version + 1))
        g.db.commit()
        return redirect(f'/sites/{site_id}', code=303)

    @editor.post('/sites/<site_id>/media')
    def upload_media(site_id):
        csrf()
        _current, site = owner_site(site_id)
        upload = request.files.get('file')
        if upload is None:
            return redirect(f'/sites/{site_id}?error=media', code=303)
        try:
            lock_site(site_id)
            filename, content_type, extension, size = inspect_upload(upload)
            used = g.db.execute(select(func.coalesce(func.sum(media.c.size), 0)).where(
                media.c.site_id == site_id,
            )).scalar_one()
            file_count = g.db.execute(select(func.count()).select_from(media).where(
                media.c.site_id == site_id,
            )).scalar_one()
            if file_count >= 100:
                raise MediaError('На сайте уже сто медиафайлов.')
            if used + size > SITE_LIMIT:
                raise MediaError('Сайт превысит лимит медиа 50 МБ.')
            media_id = secrets.token_hex(8)
            object_key = f'{site_id}/{media_id}{extension}'
            media_store.upload(upload.stream, object_key, content_type)
            try:
                g.db.execute(insert(media).values(id=media_id, site_id=site_id, filename=filename,
                                                  object_key=object_key, content_type=content_type,
                                                  size=size, created_at=now()))
                g.db.commit()
            except Exception:
                g.db.rollback()
                media_store.delete(object_key)
                raise
        except (MediaError, IntegrityError):
            g.db.rollback()
            return redirect(f'/sites/{site_id}?error=media', code=303)
        return redirect(f'/sites/{site_id}', code=303)

    @editor.post('/sites/<site_id>/media/<media_id>/delete')
    def delete_media(site_id, media_id):
        csrf()
        owner_site(site_id)
        lock_site(site_id)
        item = g.db.execute(select(media).where(
            media.c.site_id == site_id, media.c.id == media_id,
        )).mappings().first()
        if item is None:
            abort(404)
        media_url = media_store.url(item['object_key'])
        used = g.db.execute(select(pages.c.site_id).where(
            pages.c.site_id == site_id, pages.c.tree.like(f'%{media_url}%'),
        ).limit(1)).first()
        if used:
            return redirect(f'/sites/{site_id}?error=media-used', code=303)
        try:
            media_store.delete(item['object_key'])
        except MediaError:
            return redirect(f'/sites/{site_id}?error=media-delete', code=303)
        g.db.execute(delete(media).where(media.c.id == media_id))
        g.db.commit()
        return redirect(f'/sites/{site_id}', code=303)

    @editor.post('/sites/<site_id>/delete')
    def delete_site(site_id):
        csrf()
        _current, site = owner_site(site_id)
        lock_site(site_id)
        if request.form.get('confirm', '').strip().lower() != site['name'] + '.' + site['zone']:
            return redirect(f'/sites/{site_id}?error=delete', code=303)
        items = g.db.execute(select(media.c.object_key).where(media.c.site_id == site_id)).scalars().all()
        try:
            for object_key in items:
                media_store.delete(object_key)
        except MediaError:
            return redirect(f'/sites/{site_id}?error=media-delete', code=303)
        g.db.execute(delete(sites).where(sites.c.id == site_id))
        g.db.commit()
        return redirect('/', code=303)

    @editor.get('/preview/<preview_token>/<slug>')
    def preview(preview_token, slug):
        record = g.db.execute(select(sites.c.title.label('site_title'), pages.c.title,
                                     pages.c.tree, sites.c.name, sites.c.zone).join(pages).where(
            sites.c.preview_token == preview_token, pages.c.slug == slug,
        )).mappings().first()
        if record is None:
            abort(404)
        rendered = render_tree(json.loads(record['tree']))
        response = make_response(render_template('preview.html', page=record, content=rendered))
        media_origin = urlsplit(media_store.public_url)
        source = f'{media_origin.scheme}://{media_origin.netloc}' if media_origin.netloc else "'none'"
        response.headers['Content-Security-Policy'] = (
            f"default-src 'none'; style-src 'self' 'unsafe-inline'; img-src {source}; "
            f"media-src {source}; base-uri 'none'; frame-ancestors 'none'"
        )
        return response

    return editor
