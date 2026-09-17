import argparse
import json
import os
from pathlib import Path
import re
import secrets

from sqlalchemy import delete, inspect, insert, select, text

from content import source_from_tree
from database import device_codes, digest, make_engine, media, metadata, now, pages, rate_limits, servers, sessions, sites, zones


def migrate_editor(engine):
    inspector = inspect(engine)
    site_columns = {column['name'] for column in inspector.get_columns('sites')}
    page_columns = {column['name'] for column in inspector.get_columns('pages')}
    dialect = engine.dialect.name
    long_text = 'MEDIUMTEXT' if dialect in ('mysql', 'mariadb') else 'TEXT'
    with engine.begin() as db:
        if 'preview_token' not in site_columns:
            db.execute(text('ALTER TABLE sites ADD COLUMN preview_token VARCHAR(43) NULL'))
        if 'source_html' not in page_columns:
            db.execute(text(f"ALTER TABLE pages ADD COLUMN source_html {long_text} NOT NULL DEFAULT ''"))
        if 'source_css' not in page_columns:
            db.execute(text(f"ALTER TABLE pages ADD COLUMN source_css {long_text} NOT NULL DEFAULT ''"))
        legacy_pages = db.execute(select(pages.c.site_id, pages.c.slug, pages.c.tree).where(
            pages.c.source_html == '',
        )).mappings().all()
        for page in legacy_pages:
            try:
                source_html = source_from_tree(json.loads(page['tree']))
            except (json.JSONDecodeError, TypeError):
                source_html = ''
            db.execute(pages.update().where(
                pages.c.site_id == page['site_id'], pages.c.slug == page['slug'],
            ).values(source_html=source_html))
        missing = db.execute(text('SELECT id FROM sites WHERE preview_token IS NULL')).scalars().all()
        for site_id in missing:
            db.execute(text('UPDATE sites SET preview_token = :token WHERE id = :site_id'),
                       {'token': secrets.token_urlsafe(32), 'site_id': site_id})
    media.create(engine, checkfirst=True)
    inspector = inspect(engine)
    unique_columns = [set(item.get('column_names', [])) for item in inspector.get_unique_constraints('sites')]
    unique_columns += [set(item.get('column_names', [])) for item in inspector.get_indexes('sites') if item.get('unique')]
    if {'preview_token'} not in unique_columns:
        with engine.begin() as db:
            db.execute(text('CREATE UNIQUE INDEX uq_sites_preview_token ON sites (preview_token)'))
    if dialect in ('mysql', 'mariadb'):
        with engine.begin() as db:
            db.execute(text('ALTER TABLE sites MODIFY preview_token VARCHAR(43) NOT NULL'))


def main():
    parser = argparse.ArgumentParser()
    subcommands = parser.add_subparsers(dest='command', required=True)
    subcommands.add_parser('init-db')
    subcommands.add_parser('migrate')
    register = subcommands.add_parser('register-server')
    register.add_argument('id')
    register.add_argument('name')
    register.add_argument('zone')
    seed = subcommands.add_parser('seed-demo')
    seed.add_argument('--owner', required=True)
    subcommands.add_parser('cleanup')
    args = parser.parse_args()
    engine = make_engine(os.environ['NTRNET_DATABASE_URL'])
    if args.command == 'init-db':
        metadata.create_all(engine)
        with engine.begin() as db:
            if db.execute(select(zones.c.name).where(zones.c.name == 'ss13')).first() is None:
                db.execute(insert(zones).values(name='ss13', server_id=None, active=True))
        print('Schema initialized. Shared zone: ss13.')
    elif args.command == 'migrate':
        migrate_editor(engine)
        print('Editor schema migration applied.')
    elif args.command == 'register-server':
        if not re.fullmatch(r'[a-z0-9-]{3,64}', args.id) or not re.fullmatch(r'[a-z0-9]{3,24}', args.zone) or not 1 <= len(args.name) <= 128:
            parser.error('Invalid server ID, name or zone')
        token = secrets.token_urlsafe(32)
        with engine.begin() as db:
            db.execute(insert(servers).values(id=args.id, name=args.name, key_hash=digest(token), active=True))
            db.execute(insert(zones).values(name=args.zone, server_id=args.id, active=True))
        print('Server registered. Store the following key in the game config; it cannot be recovered:')
        print(token)
    elif args.command == 'seed-demo':
        if not re.fullmatch(r'[a-z0-9]{1,64}', args.owner):
            parser.error('Owner must be a canonical BYOND ckey')
        fixture = Path(__file__).parents[2] / 'tools' / 'ntrnet' / 'sites.json'
        content = json.loads(fixture.read_text(encoding='utf-8'))
        with engine.begin() as db:
            for site in content['sites']:
                if db.execute(select(sites.c.id).where(sites.c.id == site['id'])).first():
                    continue
                name, zone = site['domain'].split('.')
                db.execute(insert(sites).values(id=site['id'], name=name, zone=zone, title=site['title'],
                                               owner_ckey=args.owner, version=int(site['version']), hidden=False))
                for position, page in enumerate(site['pages']):
                    db.execute(insert(pages).values(site_id=site['id'], slug=page['slug'], title=page['title'],
                                                   position=position, tree=json.dumps(page['tree'], ensure_ascii=False)))
        print('Demo sites imported without overwriting existing sites.')
    elif args.command == 'cleanup':
        with engine.begin() as db:
            for table in (device_codes, sessions, rate_limits):
                db.execute(delete(table).where(table.c.expires_at <= now()))
        print('Expired authentication records removed.')
    engine.dispose()


if __name__ == '__main__':
    main()
