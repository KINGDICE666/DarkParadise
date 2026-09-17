import json
import os
import re
import secrets
from urllib.parse import urlsplit

from flask import Flask, abort, g, jsonify, make_response, redirect, render_template, request
from sqlalchemy import delete, insert, or_, select, update
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from werkzeug.middleware.proxy_fix import ProxyFix

from database import device_codes, digest, make_engine, now, pages, rate_limits, servers, sessions, sites, zones

CODE_TTL = 15 * 60
SESSION_TTL = 7 * 24 * 60 * 60
CODE_ALPHABET = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ'
CKEY = re.compile(r'[a-z0-9]{1,64}\Z', re.ASCII)


def create_app(database_url=None, public_url=None):
    app = Flask(__name__)
    public_url = (public_url or os.environ['NTRNET_PUBLIC_URL']).rstrip('/')
    public = urlsplit(public_url)
    local = public.scheme == 'http' and public.hostname in ('localhost', '127.0.0.1')
    if not (local or public.scheme == 'https') or not public.netloc or public.path or public.query or public.fragment or public.username:
        raise ValueError('NTRNET_PUBLIC_URL must be an HTTPS origin (HTTP allowed only on loopback)')
    engine = make_engine(database_url or os.environ['NTRNET_DATABASE_URL'])
    if engine.dialect.name == 'sqlite' and not local:
        raise ValueError('SQLite is only supported for local development')
    app.config.update(MAX_CONTENT_LENGTH=4096, MAX_FORM_MEMORY_SIZE=4096,
                      MAX_FORM_PARTS=8, TRUSTED_HOSTS=[public.hostname])
    app.extensions['ntrnet_engine'] = engine
    if os.environ.get('NTRNET_TRUST_PROXY') == '1':
        app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1)
    cookie_name = 'ntrnet_session' if local else '__Host-ntrnet_session'
    csrf_cookie = 'ntrnet_csrf' if local else '__Host-ntrnet_csrf'

    @app.before_request
    def open_connection():
        g.db = engine.connect()

    @app.teardown_request
    def close_connection(_error):
        if 'db' in g:
            g.db.close()

    @app.after_request
    def secure_headers(response):
        response.headers.update({
            'Cache-Control': 'no-store',
            'X-Robots-Tag': 'noindex, nofollow',
            'X-Content-Type-Options': 'nosniff',
            'X-Frame-Options': 'DENY',
            'Referrer-Policy': 'same-origin',
            'Content-Security-Policy': "default-src 'none'; style-src 'self'; form-action 'self'; base-uri 'none'; frame-ancestors 'none'",
        })
        return response

    @app.errorhandler(SQLAlchemyError)
    def database_unavailable(_error):
        if 'db' in g:
            g.db.rollback()
        return jsonify(error='service_unavailable'), 503

    def limit(bucket, maximum, window):
        timestamp = now()
        bucket = digest(bucket)
        try:
            with g.db.begin_nested():
                g.db.execute(insert(rate_limits).values(bucket=bucket, hits=0, expires_at=timestamp + window))
        except IntegrityError:
            pass
        g.db.execute(update(rate_limits).where(
            rate_limits.c.bucket == bucket, rate_limits.c.expires_at <= timestamp,
        ).values(hits=0, expires_at=timestamp + window))
        accepted = g.db.execute(update(rate_limits).where(
            rate_limits.c.bucket == bucket, rate_limits.c.hits < maximum,
        ).values(hits=rate_limits.c.hits + 1)).rowcount
        g.db.commit()
        if not accepted:
            abort(429)

    def game_server():
        token = request.headers.get('X-Server-Key', '')
        if not 32 <= len(token) <= 128:
            abort(401)
        server = g.db.execute(select(servers).where(
            servers.c.key_hash == digest(token), servers.c.active.is_(True),
        )).mappings().first()
        if server is None:
            abort(401)
        return server

    def identity():
        token = request.cookies.get(cookie_name, '')
        if not 32 <= len(token) <= 128:
            return None
        return g.db.execute(select(sessions.c.ckey, sessions.c.server_id).join(
            servers, sessions.c.server_id == servers.c.id,
        ).where(sessions.c.token_hash == digest(token), sessions.c.expires_at > now(),
                servers.c.active.is_(True))).mappings().first()

    def csrf_valid():
        supplied = request.form.get('csrf', '')
        expected = request.cookies.get(csrf_cookie, '')
        origin = request.headers.get('Origin')
        return (len(expected) == 43 and len(supplied) == 43
                and secrets.compare_digest(supplied, expected)
                and (origin is None or origin == public_url))

    def browser_page(error=None, status=200):
        account = identity()
        own_sites = []
        own_zones = []
        if account:
            own_sites = g.db.execute(select(sites.c.name, sites.c.zone, sites.c.title).where(
                sites.c.owner_ckey == account['ckey'],
            ).order_by(sites.c.name)).mappings().all()
            own_zones = g.db.execute(select(zones.c.name).where(zones.c.active.is_(True), or_(
                zones.c.server_id.is_(None), zones.c.server_id == account['server_id'],
            )).order_by(zones.c.name)).scalars().all()
        csrf = request.cookies.get(csrf_cookie, '')
        if len(csrf) != 43:
            csrf = secrets.token_urlsafe(32)
        response = make_response(render_template('index.html', account=account, sites=own_sites,
                                                 zones=own_zones, csrf=csrf, error=error), status)
        response.set_cookie(csrf_cookie, csrf, secure=not local, httponly=True,
                            samesite='Strict', max_age=SESSION_TTL, path='/')
        return response

    @app.get('/')
    def home():
        return browser_page()

    @app.get('/health')
    def health():
        g.db.execute(select(servers.c.id).limit(1))
        return jsonify(status='ok')

    @app.post('/api/v1/device/new')
    def new_device():
        server = game_server()
        payload = request.get_json(silent=True)
        if not isinstance(payload, dict) or set(payload) != {'ckey'}:
            abort(400)
        ckey = payload['ckey']
        if not isinstance(ckey, str) or not CKEY.fullmatch(ckey) or re.fullmatch(r'guest[0-9]+', ckey):
            abort(400)
        limit('issue-server:' + server['id'], 120, 60)
        limit('issue-user:' + server['id'] + ':' + ckey, 1, 60)
        code = ''.join(secrets.choice(CODE_ALPHABET) for _ in range(12))
        g.db.execute(update(device_codes).where(
            device_codes.c.server_id == server['id'], device_codes.c.ckey == ckey,
            device_codes.c.consumed.is_(False),
        ).values(consumed=True))
        g.db.execute(insert(device_codes).values(code_hash=digest(code), server_id=server['id'],
                                               ckey=ckey, expires_at=now() + CODE_TTL, consumed=False))
        g.db.commit()
        return jsonify(code='-'.join(code[index:index + 4] for index in range(0, 12, 4)),
                       expires_in=CODE_TTL), 201

    @app.post('/login')
    def login():
        if not csrf_valid():
            abort(403)
        limit('redeem:' + (request.remote_addr or 'unknown'), 10, 60)
        raw = request.form.get('code', '')
        code = raw.upper().replace('-', '').replace(' ', '')
        if len(code) != 12 or any(character not in CODE_ALPHABET for character in code):
            return browser_page('Код неверен, истёк или уже использован.', 400)
        code_hash = digest(code)
        claimed = g.db.execute(update(device_codes).where(
            device_codes.c.code_hash == code_hash, device_codes.c.consumed.is_(False),
            device_codes.c.expires_at > now(),
            device_codes.c.server_id.in_(select(servers.c.id).where(servers.c.active.is_(True))),
        ).values(consumed=True)).rowcount
        if not claimed:
            g.db.rollback()
            return browser_page('Код неверен, истёк или уже использован.', 400)
        device = g.db.execute(select(device_codes).where(device_codes.c.code_hash == code_hash)).mappings().one()
        previous = request.cookies.get(cookie_name, '')
        if previous:
            g.db.execute(delete(sessions).where(sessions.c.token_hash == digest(previous)))
        token = secrets.token_urlsafe(32)
        g.db.execute(insert(sessions).values(token_hash=digest(token), ckey=device['ckey'],
                                           server_id=device['server_id'], expires_at=now() + SESSION_TTL))
        g.db.commit()
        response = redirect('/', code=303)
        response.set_cookie(cookie_name, token, secure=not local, httponly=True,
                            samesite='Strict', max_age=SESSION_TTL, path='/')
        return response

    @app.post('/logout')
    def logout():
        if not csrf_valid():
            abort(403)
        token = request.cookies.get(cookie_name, '')
        g.db.execute(delete(sessions).where(sessions.c.token_hash == digest(token)))
        g.db.commit()
        response = redirect('/', code=303)
        response.delete_cookie(cookie_name, secure=not local, httponly=True, samesite='Strict', path='/')
        return response

    @app.get('/api/v1/catalog')
    def catalog():
        game_server()
        entries = g.db.execute(select(sites).where(sites.c.hidden.is_(False)).order_by(sites.c.title)).mappings().all()
        page_entries = g.db.execute(select(pages.c.site_id, pages.c.slug, pages.c.title).join(sites).where(
            sites.c.hidden.is_(False),
        ).order_by(pages.c.position, pages.c.slug)).mappings().all()
        grouped = {}
        for page in page_entries:
            grouped.setdefault(page['site_id'], []).append({'slug': page['slug'], 'title': page['title']})
        return jsonify(sites=[dict(id=site['id'], domain=site['name'] + '.' + site['zone'],
                                   title=site['title'], version=str(site['version']), pages=grouped[site['id']])
                              for site in entries if site['id'] in grouped])

    @app.get('/api/v1/sites/<site_id>/pages/<slug>')
    def page(site_id, slug):
        game_server()
        record = g.db.execute(select(pages, sites.c.version).join(sites).where(
            sites.c.id == site_id, sites.c.hidden.is_(False), pages.c.slug == slug,
        )).mappings().first()
        if record is None:
            abort(404)
        return jsonify(site_id=site_id, slug=slug, title=record['title'],
                       version=str(record['version']), tree=json.loads(record['tree']))

    @app.get('/api/v1/zones')
    def game_zones():
        server = game_server()
        records = g.db.execute(select(zones).where(or_(
            zones.c.server_id.is_(None), zones.c.server_id == server['id'],
        ))).mappings().all()
        return jsonify(zones=[dict(row) for row in records])

    return app


if __name__ == '__main__':
    from waitress import serve
    serve(create_app(), host='127.0.0.1', port=int(os.environ.get('NTRNET_PORT', '8091')),
          threads=4, connection_limit=64, channel_timeout=15, max_request_body_size=4096,
          max_request_header_size=16384)
