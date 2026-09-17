import json
from pathlib import Path
import tempfile
import unittest

from sqlalchemy import inspect, select, text

from database import make_engine, pages
from manage import migrate_editor


class MigrationTests(unittest.TestCase):
    def test_stage_two_schema_upgrades_without_losing_pages(self):
        with tempfile.TemporaryDirectory() as temporary:
            engine = make_engine('sqlite:///' + str(Path(temporary) / 'migration.db'))
            tree = {'type': 'p', 'children': [{'type': 'text', 'text': 'Legacy'}]}
            with engine.begin() as db:
                db.execute(text('CREATE TABLE servers (id VARCHAR(64) PRIMARY KEY)'))
                db.execute(text('CREATE TABLE zones (name VARCHAR(24) PRIMARY KEY, server_id VARCHAR(64))'))
                db.execute(text('CREATE TABLE sites (id VARCHAR(64) PRIMARY KEY, name VARCHAR(24) NOT NULL, '
                                'zone VARCHAR(24) NOT NULL, owner_ckey VARCHAR(64) NOT NULL, title VARCHAR(160) '
                                'NOT NULL, version BIGINT NOT NULL, hidden BOOLEAN NOT NULL)'))
                db.execute(text('CREATE TABLE pages (site_id VARCHAR(64) NOT NULL, slug VARCHAR(64) NOT NULL, '
                                'title VARCHAR(160) NOT NULL, position INTEGER NOT NULL, tree TEXT NOT NULL, '
                                'PRIMARY KEY (site_id, slug))'))
                db.execute(text("INSERT INTO sites VALUES ('legacy', 'legacy', 'ss13', 'alice', 'Legacy', 1, 0)"))
                db.execute(text('INSERT INTO pages VALUES (:site, :slug, :title, 0, :tree)'),
                           dict(site='legacy', slug='index', title='Home', tree=json.dumps(tree)))
            migrate_editor(engine)
            migrate_editor(engine)
            inspector = inspect(engine)
            self.assertIn('preview_token', {column['name'] for column in inspector.get_columns('sites')})
            self.assertIn('media', inspector.get_table_names())
            with engine.connect() as db:
                page = db.execute(select(pages.c.source_html, pages.c.tree)).mappings().one()
            self.assertIn('Legacy', page['source_html'])
            self.assertEqual(json.loads(page['tree']), tree)
            engine.dispose()


if __name__ == '__main__':
    unittest.main()
