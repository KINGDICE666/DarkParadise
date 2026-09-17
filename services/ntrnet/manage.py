import argparse
import json
import os
from pathlib import Path
import re
import secrets

from sqlalchemy import delete, insert, select

from database import device_codes, digest, make_engine, metadata, now, pages, rate_limits, servers, sessions, sites, zones


def main():
    parser = argparse.ArgumentParser()
    subcommands = parser.add_subparsers(dest='command', required=True)
    subcommands.add_parser('init-db')
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
