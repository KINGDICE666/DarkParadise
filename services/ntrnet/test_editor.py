from io import BytesIO
import base64
from pathlib import Path
import re
import tempfile
import unittest

from sqlalchemy import delete, insert, select

from app import create_app
from database import digest, media, metadata, pages, servers, sites, zones
from storage import MediaError


class FakeStore:
    enabled = True
    public_url = 'https://media.wiki-ss13.space'

    def __init__(self):
        self.objects = {}

    def url(self, object_key):
        return self.public_url + '/' + object_key

    def upload(self, stream, object_key, content_type):
        self.objects[object_key] = (stream.read(), content_type)

    def delete(self, object_key):
        if object_key not in self.objects:
            raise MediaError('missing')
        del self.objects[object_key]


class EditorTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temporary = tempfile.TemporaryDirectory()
        cls.url = 'sqlite:///' + str(Path(cls.temporary.name) / 'editor.db')

    @classmethod
    def tearDownClass(cls):
        cls.temporary.cleanup()

    def setUp(self):
        self.store = FakeStore()
        self.app = create_app(self.url, 'http://localhost', self.store)
        self.app.testing = True
        self.engine = self.app.extensions['ntrnet_engine']
        metadata.create_all(self.engine)
        with self.engine.begin() as db:
            for table in reversed(metadata.sorted_tables):
                db.execute(delete(table))
            db.execute(insert(servers).values(id='dark-paradise', name='Dark Paradise',
                                              key_hash=digest('a' * 43), active=True))
            db.execute(insert(zones), [
                dict(name='ss13', server_id=None, active=True),
                dict(name='ss13dp', server_id='dark-paradise', active=True),
                dict(name='retired', server_id='dark-paradise', active=False),
            ])
        self.browser = self.app.test_client()
        issued = self.browser.post('/api/v1/device/new', json={'ckey': 'alice'},
                                   headers={'X-Server-Key': 'a' * 43}).json['code']
        self.browser.post('/login', data={'code': issued, 'csrf': self.csrf()})

    def tearDown(self):
        self.engine.dispose()

    def csrf(self):
        html = self.browser.get('/').get_data(as_text=True)
        return re.search(r'name="csrf" value="([^"]+)"', html)[1]

    def create_site(self, name='journal', zone='ss13dp', title='Station journal'):
        response = self.browser.post('/sites', data={
            'csrf': self.csrf(), 'name': name, 'zone': zone, 'title': title,
        })
        with self.engine.connect() as db:
            site = db.execute(select(sites).where(sites.c.name == name)).mappings().first()
        return response, site

    def test_create_edit_preview_and_game_contract(self):
        response, site = self.create_site()
        self.assertEqual(response.status_code, 303)
        self.assertIsNotNone(site)
        with self.engine.connect() as db:
            page = db.execute(select(pages).where(pages.c.site_id == site['id'])).mappings().one()
        self.assertEqual(page['slug'], 'index')
        saved = self.browser.post(f'/sites/{site["id"]}/pages/index', data={
            'csrf': self.csrf(), 'title': 'News',
            'source_html': '<h1 class="accent">Hello &lt;crew&gt;</h1>',
            'source_css': '.accent { color: #74e3bc; text-align: center; }',
        })
        self.assertEqual(saved.status_code, 303)
        game = self.browser.get(f'/api/v1/sites/{site["id"]}/pages/index',
                                headers={'X-Server-Key': 'a' * 43})
        self.assertEqual(game.status_code, 200)
        self.assertEqual(game.json['tree']['children'][0]['style']['textAlign'], 'center')
        preview = self.app.test_client().get(f'/preview/{site["preview_token"]}/index')
        self.assertIn('Hello &lt;crew&gt;', preview.get_data(as_text=True))
        self.assertIn("frame-ancestors 'none'", preview.headers['Content-Security-Policy'])

    def test_rejected_content_does_not_replace_page(self):
        _response, site = self.create_site()
        with self.engine.connect() as db:
            before = db.execute(select(pages.c.tree).where(pages.c.site_id == site['id'])).scalar_one()
        response = self.browser.post(f'/sites/{site["id"]}/pages/index', data={
            'csrf': self.csrf(), 'title': 'Bad', 'source_html': '<script>alert(1)</script>', 'source_css': '',
        })
        self.assertEqual(response.status_code, 400)
        with self.engine.connect() as db:
            after = db.execute(select(pages.c.tree).where(pages.c.site_id == site['id'])).scalar_one()
        self.assertEqual(before, after)

    def test_site_limits_zones_and_alphabets(self):
        for name, zone in (('mixа', 'ss13dp'), ('valid', 'retired'), ('ab', 'ss13dp')):
            response, site = self.create_site(name, zone)
            self.assertEqual(response.status_code, 303)
            self.assertIsNone(site)
        for name in ('one', 'two', 'three'):
            self.assertIsNotNone(self.create_site(name)[1])
        self.assertIsNone(self.create_site('four')[1])

    def test_page_limit_duplicate_and_delete(self):
        _response, site = self.create_site()
        created = self.browser.post(f'/sites/{site["id"]}/pages', data={
            'csrf': self.csrf(), 'slug': 'news', 'title': 'News',
        })
        self.assertEqual(created.status_code, 303)
        duplicate = self.browser.post(f'/sites/{site["id"]}/pages', data={
            'csrf': self.csrf(), 'slug': 'news', 'title': 'Again',
        })
        self.assertIn('error=duplicate', duplicate.location)
        self.assertEqual(self.browser.post(f'/sites/{site["id"]}/pages/index/delete',
                                           data={'csrf': self.csrf()}).status_code, 400)
        self.assertEqual(self.browser.post(f'/sites/{site["id"]}/pages/news/delete',
                                           data={'csrf': self.csrf()}).status_code, 303)

    def test_upload_insert_and_delete_media(self):
        _response, site = self.create_site()
        image = base64.b64decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII='
        )
        uploaded = self.browser.post(f'/sites/{site["id"]}/media', data={
            'csrf': self.csrf(), 'file': (BytesIO(image), 'station.png'),
        }, content_type='multipart/form-data')
        self.assertEqual(uploaded.status_code, 303)
        with self.engine.connect() as db:
            item = db.execute(select(media)).mappings().one()
        saved = self.browser.post(f'/sites/{site["id"]}/pages/index', data={
            'csrf': self.csrf(), 'title': 'Gallery',
            'source_html': f'<img data-media="{item["id"]}" alt="Station">', 'source_css': '',
        })
        self.assertEqual(saved.status_code, 303)
        game = self.browser.get(f'/api/v1/sites/{site["id"]}/pages/index',
                                headers={'X-Server-Key': 'a' * 43}).json
        self.assertEqual(game['tree']['children'][0]['type'], 'image')
        self.assertTrue(game['tree']['children'][0]['src'].startswith(self.store.public_url))
        blocked = self.browser.post(f'/sites/{site["id"]}/media/{item["id"]}/delete',
                                    data={'csrf': self.csrf()})
        self.assertIn('error=media-used', blocked.location)
        self.browser.post(f'/sites/{site["id"]}/pages/index', data={
            'csrf': self.csrf(), 'title': 'Gallery', 'source_html': '<p>Empty</p>', 'source_css': '',
        })
        removed = self.browser.post(f'/sites/{site["id"]}/media/{item["id"]}/delete',
                                    data={'csrf': self.csrf()})
        self.assertEqual(removed.status_code, 303)
        self.assertFalse(self.store.objects)

    def test_other_author_cannot_open_editor(self):
        _response, site = self.create_site()
        outsider = self.app.test_client()
        self.assertEqual(outsider.get(f'/sites/{site["id"]}').status_code, 401)

    def test_site_delete_requires_full_domain(self):
        _response, site = self.create_site()
        blocked = self.browser.post(f'/sites/{site["id"]}/delete',
                                    data={'csrf': self.csrf(), 'confirm': 'wrong.ss13'})
        self.assertIn('error=delete', blocked.location)
        removed = self.browser.post(f'/sites/{site["id"]}/delete',
                                    data={'csrf': self.csrf(), 'confirm': 'journal.ss13dp'})
        self.assertEqual(removed.status_code, 303)
        with self.engine.connect() as db:
            self.assertIsNone(db.execute(select(sites).where(sites.c.id == site['id'])).first())


if __name__ == '__main__':
    unittest.main()
