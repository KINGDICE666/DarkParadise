import html
from html.parser import HTMLParser
import json
import re
from urllib.parse import urlsplit


MAX_SOURCE = 64 * 1024
MAX_TREE = 64 * 1024
MAX_NODES = 1024
MAX_DEPTH = 16
TAGS = {'div', 'p', 'span', 'h1', 'h2', 'h3', 'h4', 'strong', 'em', 'u', 's',
        'ul', 'ol', 'li', 'blockquote', 'pre', 'code', 'br', 'hr'}
VOID_TAGS = {'br', 'hr', 'img'}
STYLE_NAMES = {
    'background-color': 'backgroundColor',
    'border': 'border',
    'border-color': 'borderColor',
    'border-radius': 'borderRadius',
    'border-style': 'borderStyle',
    'border-width': 'borderWidth',
    'color': 'color',
    'font-size': 'fontSize',
    'font-style': 'fontStyle',
    'font-weight': 'fontWeight',
    'line-height': 'lineHeight',
    'margin': 'margin',
    'margin-bottom': 'marginBottom',
    'margin-left': 'marginLeft',
    'margin-right': 'marginRight',
    'margin-top': 'marginTop',
    'max-width': 'maxWidth',
    'padding': 'padding',
    'padding-bottom': 'paddingBottom',
    'padding-left': 'paddingLeft',
    'padding-right': 'paddingRight',
    'padding-top': 'paddingTop',
    'text-align': 'textAlign',
    'text-decoration': 'textDecoration',
    'white-space': 'whiteSpace',
    'width': 'width',
}
COLOR = re.compile(r'(?:#[0-9a-fA-F]{3}(?:[0-9a-fA-F]{3})?|[a-zA-Z]{3,20})\Z')
LENGTH = re.compile(r'(?:0|(?:[0-9]|[1-9][0-9]{0,2})(?:\.[0-9]{1,2})?(?:px|em|rem|%))\Z')
SPACING = re.compile(r'(?:0|(?:[0-9]|[1-9][0-9]{0,2})(?:\.[0-9]{1,2})?(?:px|em|rem|%))(?:\s+(?:0|(?:[0-9]|[1-9][0-9]{0,2})(?:\.[0-9]{1,2})?(?:px|em|rem|%))){0,3}\Z')
SELECTOR = re.compile(r'(?:(?P<tag>[a-z][a-z0-9]*)|)(?:(?P<class>\.[a-zA-Z][\w-]*)|)(?:(?P<id>#[a-zA-Z][\w-]*)|)\Z')
SITE_ID = re.compile(r'[a-z0-9](?:[a-z0-9_-]{0,63})\Z')
SLUG = re.compile(r'[a-z0-9](?:[a-z0-9-]{0,62}[a-z0-9])?\Z')
MEDIA_URL = re.compile(r'https://media\.wiki-ss13\.space/[a-z0-9]{32}/([a-f0-9]{16})\.(?:png|jpg|gif|webp|mp4)\Z')


class ContentError(ValueError):
    pass


def _style_value(name, value):
    value = ' '.join(value.strip().split())
    if any(token in value.lower() for token in ('url', 'var(', 'calc(', 'expression', '@', '\\')):
        return None
    if name in ('color', 'background-color', 'border-color'):
        return value if COLOR.fullmatch(value) else None
    if name in ('font-size', 'line-height', 'max-width', 'width', 'border-radius', 'border-width'):
        return value if LENGTH.fullmatch(value) else None
    if name.startswith('margin') or name.startswith('padding'):
        return value if SPACING.fullmatch(value) else None
    choices = {
        'border-style': {'none', 'solid', 'dashed', 'dotted', 'double'},
        'font-style': {'normal', 'italic'},
        'font-weight': {'normal', 'bold', '400', '500', '600', '700'},
        'text-align': {'left', 'center', 'right', 'justify'},
        'text-decoration': {'none', 'underline', 'line-through'},
        'white-space': {'normal', 'pre-wrap'},
    }
    if name == 'border':
        parts = value.split()
        return value if 1 <= len(parts) <= 3 and all(
            LENGTH.fullmatch(part) or part in choices['border-style'] or COLOR.fullmatch(part) for part in parts
        ) else None
    return value if value in choices.get(name, set()) else None


def parse_css(source):
    if len(source.encode('utf-8')) > MAX_SOURCE:
        raise ContentError('CSS превышает 64 КБ.')
    source = re.sub(r'/\*.*?\*/', '', source, flags=re.S)
    if '@' in source:
        raise ContentError('Правила CSS с @ не поддерживаются.')
    rules = []
    position = 0
    for match in re.finditer(r'([^{}]+)\{([^{}]*)\}', source):
        if source[position:match.start()].strip():
            raise ContentError('Не удалось разобрать CSS.')
        position = match.end()
        styles = {}
        for declaration in match.group(2).split(';'):
            if not declaration.strip():
                continue
            if ':' not in declaration:
                raise ContentError('В CSS есть незавершённое свойство.')
            name, value = (part.strip().lower() for part in declaration.split(':', 1))
            if name not in STYLE_NAMES:
                raise ContentError(f'Свойство CSS «{name}» не поддерживается.')
            value = _style_value(name, value)
            if value is None:
                raise ContentError(f'Недопустимое значение свойства «{name}».')
            styles[STYLE_NAMES[name]] = value
        for selector in match.group(1).split(','):
            selector = selector.strip()
            parsed = SELECTOR.fullmatch(selector)
            if not parsed or not any(parsed.groupdict().values()):
                raise ContentError(f'Селектор «{selector}» не поддерживается.')
            tag = parsed.group('tag')
            if tag and tag not in TAGS and tag not in ('a', 'img', 'video'):
                raise ContentError(f'Селектор «{selector}» не поддерживается.')
            rules.append((parsed.groupdict(), dict(styles)))
    if source[position:].strip():
        raise ContentError('Не удалось разобрать CSS.')
    return rules


def _matches(selector, tag, attributes):
    if selector['tag'] and selector['tag'] != tag:
        return False
    if selector['class'] and selector['class'][1:] not in attributes.get('class', '').split():
        return False
    return not selector['id'] or selector['id'][1:] == attributes.get('id')


class TreeParser(HTMLParser):
    def __init__(self, rules, media):
        super().__init__(convert_charrefs=True)
        self.root = {'type': 'div', 'children': []}
        self.stack = [(self.root, 'div')]
        self.rules = rules
        self.media = media
        self.nodes = 1

    def add(self, node):
        self.nodes += 1
        if self.nodes > MAX_NODES:
            raise ContentError('На странице больше 1024 элементов.')
        self.stack[-1][0].setdefault('children', []).append(node)

    def handle_starttag(self, tag, attrs):
        tag = tag.lower()
        attributes = dict(attrs)
        if any(name.lower().startswith('on') or name.lower() == 'style' for name in attributes):
            raise ContentError('Обработчики событий и атрибут style запрещены.')
        if tag == 'a':
            node = self._link(attributes)
        elif tag in ('img', 'video'):
            node = self._media(tag, attributes)
        elif tag in TAGS:
            node = {'type': tag}
        else:
            raise ContentError(f'Тег <{tag}> не поддерживается.')
        style = {}
        for selector, properties in self.rules:
            if _matches(selector, tag, attributes):
                style.update(properties)
        if style:
            node['style'] = style
        if tag == 'img':
            self.add(node)
            return
        if tag in ('br', 'hr'):
            self.add(node)
            return
        node['children'] = []
        self.add(node)
        self.stack.append((node, tag))
        if len(self.stack) > MAX_DEPTH:
            raise ContentError('Вложенность страницы превышает 16 уровней.')

    def handle_startendtag(self, tag, attrs):
        self.handle_starttag(tag, attrs)
        if tag.lower() == 'video':
            self.handle_endtag(tag)

    def handle_endtag(self, tag):
        tag = tag.lower()
        if tag in VOID_TAGS:
            return
        if len(self.stack) == 1 or self.stack[-1][1] != tag:
            raise ContentError(f'Закрывающий тег </{tag}> стоит не на месте.')
        self.stack.pop()

    def handle_data(self, data):
        if data:
            self.add({'type': 'text', 'text': data})

    def handle_comment(self, _data):
        return

    def close(self):
        super().close()
        if len(self.stack) != 1:
            raise ContentError(f'Тег <{self.stack[-1][1]}> не закрыт.')

    def _link(self, attributes):
        target = attributes.get('href', '')
        parsed = urlsplit(target)
        if parsed.scheme == 'ntrnet' and not parsed.query and not parsed.fragment:
            site_id = parsed.netloc
            slug = parsed.path.strip('/') or 'index'
        elif not parsed.scheme and not parsed.netloc and not parsed.query and not parsed.fragment:
            parts = parsed.path.strip('/').split('/')
            if len(parts) != 2:
                raise ContentError('Внутренняя ссылка должна иметь вид /ID_САЙТА/страница.')
            site_id, slug = parts
        else:
            raise ContentError('Разрешены только внутренние ссылки НТрнета.')
        if not SITE_ID.fullmatch(site_id) or not SLUG.fullmatch(slug):
            raise ContentError('Внутренняя ссылка содержит неверный адрес.')
        return {'type': 'link', 'site_id': site_id, 'slug': slug}

    def _media(self, tag, attributes):
        media_id = attributes.get('data-media', '')
        item = self.media.get(media_id)
        if item is None:
            raise ContentError(f'Медиафайл «{media_id}» не найден на этом сайте.')
        expected = 'image/' if tag == 'img' else 'video/'
        if not item['content_type'].startswith(expected):
            raise ContentError(f'Медиафайл «{media_id}» не подходит для тега <{tag}>.')
        node = {'type': 'image' if tag == 'img' else 'video', 'src': item['url']}
        if tag == 'img':
            node['alt'] = attributes.get('alt', '')[:160]
        return node


def compile_page(source_html, source_css, media=()):
    if len(source_html.encode('utf-8')) > MAX_SOURCE:
        raise ContentError('HTML превышает 64 КБ.')
    media_by_id = {item['id']: item for item in media}
    parser = TreeParser(parse_css(source_css), media_by_id)
    try:
        parser.feed(source_html)
        parser.close()
    except ContentError:
        raise
    except Exception as error:
        raise ContentError('Не удалось разобрать HTML.') from error
    encoded = json.dumps(parser.root, ensure_ascii=False, separators=(',', ':'))
    if len(encoded.encode('utf-8')) > MAX_TREE:
        raise ContentError('Готовая страница превышает 64 КБ.')
    return parser.root


def render_tree(tree):
    def render(node):
        if not isinstance(node, dict):
            return ''
        node_type = node.get('type')
        if node_type == 'text':
            return html.escape(node.get('text', '')) if isinstance(node.get('text'), str) else ''
        style = node.get('style', {})
        safe_style = []
        if isinstance(style, dict):
            for key, value in style.items():
                name = next((name for name, target in STYLE_NAMES.items() if target == key), None)
                if name and isinstance(value, str) and _style_value(name, value) == value:
                    safe_style.append(f'{name}:{html.escape(value, quote=True)}')
        style_text = ';'.join(safe_style)
        style_attr = f' style="{style_text}"' if style_text else ''
        if node_type == 'link':
            children = ''.join(render(child) for child in node.get('children', []))
            return f'<span class="ntrnet-link"{style_attr}>{children}</span>'
        if node_type == 'image':
            if not isinstance(node.get('src'), str) or not MEDIA_URL.fullmatch(node['src']):
                return ''
            alt = node.get('alt', '')
            alt = alt if isinstance(alt, str) else ''
            return f'<img src="{html.escape(node["src"], quote=True)}" alt="{html.escape(alt, quote=True)}"{style_attr}>'
        if node_type == 'video':
            if not isinstance(node.get('src'), str) or not MEDIA_URL.fullmatch(node['src']):
                return ''
            return f'<video src="{html.escape(node["src"], quote=True)}" controls preload="metadata"{style_attr}></video>'
        if node_type not in TAGS:
            return ''
        if node_type in ('br', 'hr'):
            return f'<{node_type}{style_attr}>'
        children = ''.join(render(child) for child in node.get('children', []))
        return f'<{node_type}{style_attr}>{children}</{node_type}>'
    return render(tree)


def source_from_tree(tree):
    def render(node, depth=0):
        if depth > MAX_DEPTH or not isinstance(node, dict):
            return ''
        node_type = node.get('type')
        if node_type == 'text':
            return html.escape(node.get('text', '')) if isinstance(node.get('text'), str) else ''
        child_nodes = node.get('children', [])
        children = ''.join(render(child, depth + 1) for child in child_nodes) if isinstance(child_nodes, list) else ''
        site_id = node.get('site_id')
        slug = node.get('slug')
        if (node_type == 'link' and isinstance(site_id, str) and isinstance(slug, str)
                and SITE_ID.fullmatch(site_id) and SLUG.fullmatch(slug)):
            return f'<a href="/{node["site_id"]}/{node["slug"]}">{children}</a>'
        if node_type in ('image', 'video') and isinstance(node.get('src'), str):
            match = MEDIA_URL.fullmatch(node['src'])
            if match:
                if node_type == 'image':
                    alt = node.get('alt', '')
                    alt = alt if isinstance(alt, str) else ''
                    return f'<img data-media="{match[1]}" alt="{html.escape(alt, quote=True)}">'
                return f'<video data-media="{match[1]}"></video>'
        if node_type not in TAGS:
            return children
        if node_type in ('br', 'hr'):
            return f'<{node_type}>'
        return f'<{node_type}>{children}</{node_type}>'
    return render(tree)
