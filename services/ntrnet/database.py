import hashlib
import secrets
import time

from sqlalchemy import (
    BigInteger, Boolean, Column, ForeignKey, Integer, MetaData, String,
    Table, Text, UniqueConstraint, create_engine, event,
)
from sqlalchemy.dialects.mysql import MEDIUMTEXT

metadata = MetaData()
table_options = {'mysql_engine': 'InnoDB', 'mysql_charset': 'utf8mb4', 'mysql_collate': 'utf8mb4_bin'}

servers = Table('servers', metadata,
    Column('id', String(64), primary_key=True),
    Column('name', String(128), nullable=False),
    Column('key_hash', String(64), nullable=False, unique=True),
    Column('active', Boolean, nullable=False, default=True),
    **table_options)

zones = Table('zones', metadata,
    Column('name', String(24), primary_key=True),
    Column('server_id', String(64), ForeignKey('servers.id'), nullable=True),
    Column('active', Boolean, nullable=False, default=True),
    **table_options)

sites = Table('sites', metadata,
    Column('id', String(64), primary_key=True),
    Column('name', String(24), nullable=False),
    Column('zone', String(24), ForeignKey('zones.name'), nullable=False),
    Column('owner_ckey', String(64), nullable=False, index=True),
    Column('title', String(160), nullable=False),
    Column('version', BigInteger, nullable=False, default=1),
    Column('hidden', Boolean, nullable=False, default=False),
    Column('preview_token', String(43), nullable=False, unique=True, default=lambda: secrets.token_urlsafe(32)),
    UniqueConstraint('name', 'zone', name='uq_site_domain'),
    **table_options)

pages = Table('pages', metadata,
    Column('site_id', String(64), ForeignKey('sites.id', ondelete='CASCADE'), primary_key=True),
    Column('slug', String(64), primary_key=True),
    Column('title', String(160), nullable=False),
    Column('position', Integer, nullable=False),
    Column('source_html', Text().with_variant(MEDIUMTEXT(), 'mysql', 'mariadb'), nullable=False, default=''),
    Column('source_css', Text().with_variant(MEDIUMTEXT(), 'mysql', 'mariadb'), nullable=False, default=''),
    Column('tree', Text().with_variant(MEDIUMTEXT(), 'mysql', 'mariadb'), nullable=False),
    **table_options)

media = Table('media', metadata,
    Column('id', String(32), primary_key=True),
    Column('site_id', String(64), ForeignKey('sites.id', ondelete='CASCADE'), nullable=False, index=True),
    Column('filename', String(160), nullable=False),
    Column('object_key', String(160), nullable=False, unique=True),
    Column('content_type', String(64), nullable=False),
    Column('size', BigInteger, nullable=False),
    Column('created_at', BigInteger, nullable=False),
    **table_options)

device_codes = Table('device_codes', metadata,
    Column('code_hash', String(64), primary_key=True),
    Column('server_id', String(64), ForeignKey('servers.id'), nullable=False),
    Column('ckey', String(64), nullable=False, index=True),
    Column('expires_at', BigInteger, nullable=False, index=True),
    Column('consumed', Boolean, nullable=False, default=False),
    **table_options)

sessions = Table('sessions', metadata,
    Column('token_hash', String(64), primary_key=True),
    Column('ckey', String(64), nullable=False, index=True),
    Column('server_id', String(64), ForeignKey('servers.id'), nullable=False),
    Column('expires_at', BigInteger, nullable=False, index=True),
    **table_options)

rate_limits = Table('rate_limits', metadata,
    Column('bucket', String(64), primary_key=True),
    Column('hits', Integer, nullable=False),
    Column('expires_at', BigInteger, nullable=False, index=True),
    **table_options)


def digest(value):
    return hashlib.sha256(value.encode('utf-8')).hexdigest()


def now():
    return int(time.time())


def make_engine(url):
    if url.startswith('sqlite:'):
        engine = create_engine(url, connect_args={'timeout': 15})

        @event.listens_for(engine, 'connect')
        def sqlite_foreign_keys(connection, _record):
            connection.execute('PRAGMA foreign_keys=ON')
        return engine
    return create_engine(url, pool_size=4, max_overflow=0, pool_pre_ping=True,
                         pool_recycle=300, hide_parameters=True,
                         connect_args={'connect_timeout': 5, 'read_timeout': 10, 'write_timeout': 10})
