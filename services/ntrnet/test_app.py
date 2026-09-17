from concurrent.futures import ThreadPoolExecutor
import json
import os
from pathlib import Path
import re
import tempfile
import unittest

from sqlalchemy import delete, insert, select, update
from sqlalchemy.engine import make_url

from app import create_app
from database import device_codes, digest, metadata, now, pages, rate_limits, servers, sessions, sites, zones


class AuthTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temporary = tempfile.TemporaryDirectory()
        cls.url = os.environ.get('NTRNET_TEST_DATABASE_URL', 'sqlite:///' + str(Path(cls.temporary.name) / 'test.db'))
        parsed = make_url(cls.url)
        if parsed.drivername != 'sqlite' and not (parsed.database or '').startswith('ntrnet_test'):
            raise ValueError('Tests require a dedicated database named ntrnet_test*')
        cls.app = create_app(cls.url, 'http://localhost')
        cls.app.testing = True
        cls.engine = cls.app.extensions['ntrnet_engine']
        metadata.create_all(cls.engine)

    @classmethod
    def tearDownClass(cls):
        cls.engine.dispose()
        cls.temporary.cleanup()

    def setUp(self):
        with self.engine.begin() as db:
            for table in reversed(metadata.sorted_tables):
                db.execute(delete(table))
            db.execute(insert(servers), [
                dict(id='dark-paradise', name='Dark Paradise', key_hash=digest('a' * 43), active=True),
                dict(id='other', name='Other', key_hash=digest('b' * 43), active=True),
            ])
            db.execute(insert(zones), [
                dict(name='ss13', server_id=None, active=True),
                dict(name='ss13dp', server_id='dark-paradise', active=True),
                dict(name='other', server_id='other', active=True),
            ])
            db.execute(insert(sites), [
                dict(id='alice', name='alice', zone='ss13dp', owner_ckey='alice', title='Alice site', version=1, hidden=False),
                dict(id='bob', name='bob', zone='other', owner_ckey='bob', title='Bob private title', version=1, hidden=False),
            ])
            for site in ('alice', 'bob'):
                db.execute(insert(pages).values(site_id=site, slug='index', title='Home', position=0,
                                               tree=json.dumps({'type': 'text', 'text': 'Hello'})))
        self.browser = self.app.test_client()

    def issue(self, ckey='alice', key='a' * 43):
        return self.app.test_client().post('/api/v1/device/new', json={'ckey': ckey}, headers={'X-Server-Key': key})

    def csrf(self, browser):
        response = browser.get('/')
        return re.search(r'name="csrf" value="([^"]+)"', response.get_data(as_text=True))[1]

    def redeem(self, code, browser=None, **kwargs):
        browser = browser or self.browser
        return browser.post('/login', data={'code': code, 'csrf': self.csrf(browser)}, **kwargs)

    def test_login_and_owner_scope(self):
        issued = self.issue()
        self.assertEqual(issued.status_code, 201)
        self.assertEqual(issued.json['expires_in'], 900)
        self.assertEqual(self.redeem(issued.json['code']).status_code, 303)
        page = self.browser.get('/').get_data(as_text=True)
        self.assertIn('alice.ss13dp', page)
        self.assertNotIn('Bob private title', page)
        self.assertIn('<code>.ss13</code>', page)
        self.assertIn('<code>.ss13dp</code>', page)
        self.assertNotIn('<code>.other</code>', page)

    def test_no_public_catalog_even_with_browser_session(self):
        self.redeem(self.issue().json['code'])
        self.assertEqual(self.browser.get('/api/v1/catalog').status_code, 401)
        self.assertEqual(self.browser.get('/api/v1/sites/alice/pages/index').status_code, 401)

    def test_unregistered_server_cannot_issue(self):
        self.assertEqual(self.issue(key='c' * 43).status_code, 401)
        self.assertEqual(self.issue(key='').status_code, 401)

    def test_code_is_single_use(self):
        code = self.issue().json['code']
        self.assertEqual(self.redeem(code).status_code, 303)
        self.assertEqual(self.redeem(code, self.app.test_client()).status_code, 400)

    def test_expired_code(self):
        code = self.issue().json['code']
        with self.engine.begin() as db:
            db.execute(update(device_codes).values(expires_at=now() - 1))
        self.assertEqual(self.redeem(code).status_code, 400)

    def test_atomic_claim_under_race(self):
        code = self.issue().json['code']
        browsers = [self.app.test_client(), self.app.test_client()]
        tokens = [self.csrf(browser) for browser in browsers]

        def claim(index):
            return browsers[index].post('/login', data={'code': code, 'csrf': tokens[index]}).status_code

        with ThreadPoolExecutor(max_workers=2) as pool:
            statuses = list(pool.map(claim, (0, 1)))
        self.assertEqual(sorted(statuses), [303, 400])
        with self.engine.connect() as db:
            self.assertEqual(len(db.execute(select(sessions)).all()), 1)

    def test_csrf_and_cross_origin_rejected_without_consuming_code(self):
        code = self.issue().json['code']
        self.assertEqual(self.browser.post('/login', data={'code': code}).status_code, 403)
        self.assertEqual(self.redeem(code, headers={'Origin': 'https://evil.example'}).status_code, 403)
        self.assertEqual(self.redeem(code).status_code, 303)

    def test_reissue_revokes_earlier_code(self):
        first = self.issue().json['code']
        self.assertEqual(self.issue().status_code, 429)
        with self.engine.begin() as db:
            db.execute(delete(rate_limits))
        second = self.issue().json['code']
        self.assertEqual(self.redeem(first).status_code, 400)
        self.assertEqual(self.redeem(second).status_code, 303)

    def test_rate_limit_and_forwarded_header_not_trusted_by_default(self):
        token = self.csrf(self.browser)
        for index in range(10):
            response = self.browser.post('/login', data={'code': 'WRONG', 'csrf': token},
                                         headers={'X-Forwarded-For': f'192.0.2.{index}'})
            self.assertEqual(response.status_code, 400)
        self.assertEqual(self.browser.post('/login', data={'code': 'WRONG', 'csrf': token}).status_code, 429)

    def test_logout_revokes_session(self):
        self.redeem(self.issue().json['code'])
        token = self.browser.get_cookie('ntrnet_session').value
        self.assertEqual(self.browser.post('/logout', data={'csrf': self.csrf(self.browser)}).status_code, 303)
        replay = self.app.test_client()
        replay.set_cookie('ntrnet_session', token)
        self.assertNotIn('alice.ss13dp', replay.get('/').get_data(as_text=True))

    def test_session_expiry(self):
        self.redeem(self.issue().json['code'])
        with self.engine.begin() as db:
            db.execute(update(sessions).values(expires_at=now() - 1))
        self.assertNotIn('alice.ss13dp', self.browser.get('/').get_data(as_text=True))

    def test_inactive_server_revokes_codes_and_sessions(self):
        self.redeem(self.issue().json['code'])
        other_code = self.issue('charlie').json['code']
        with self.engine.begin() as db:
            db.execute(update(servers).where(servers.c.id == 'dark-paradise').values(active=False))
        self.assertEqual(self.issue('david').status_code, 401)
        self.assertEqual(self.redeem(other_code, self.app.test_client()).status_code, 400)
        self.assertNotIn('alice.ss13dp', self.browser.get('/').get_data(as_text=True))

    def test_zone_retirement_preserves_existing_site(self):
        with self.engine.begin() as db:
            db.execute(update(zones).where(zones.c.name == 'ss13dp').values(active=False))
        self.redeem(self.issue().json['code'])
        html = self.browser.get('/').get_data(as_text=True)
        self.assertIn('alice.ss13dp', html)
        self.assertNotIn('<code>.ss13dp</code>', html)
        response = self.browser.get('/api/v1/sites/alice/pages/index', headers={'X-Server-Key': 'a' * 43})
        self.assertEqual(response.status_code, 200)

    def test_hidden_site_unavailable_in_game(self):
        with self.engine.begin() as db:
            db.execute(update(sites).where(sites.c.id == 'bob').values(hidden=True))
        headers = {'X-Server-Key': 'a' * 43}
        catalog = self.browser.get('/api/v1/catalog', headers=headers)
        self.assertEqual([site['id'] for site in catalog.json['sites']], ['alice'])
        self.assertEqual(self.browser.get('/api/v1/sites/bob/pages/index', headers=headers).status_code, 404)

    def test_game_contract(self):
        headers = {'X-Server-Key': 'a' * 43}
        catalog = self.browser.get('/api/v1/catalog', headers=headers).json
        for site in catalog['sites']:
            for entry in site['pages']:
                response = self.browser.get(f"/api/v1/sites/{site['id']}/pages/{entry['slug']}", headers=headers)
                self.assertEqual(response.status_code, 200)
                self.assertEqual(response.json['version'], site['version'])
                self.assertIsInstance(response.json['tree'], dict)

    def test_only_hashes_stored(self):
        code = self.issue().json['code']
        self.redeem(code)
        token = self.browser.get_cookie('ntrnet_session').value
        with self.engine.connect() as db:
            saved_code = db.execute(select(device_codes.c.code_hash)).scalar_one()
            saved_token = db.execute(select(sessions.c.token_hash)).scalar_one()
        self.assertEqual(saved_code, digest(code.replace('-', '')))
        self.assertEqual(saved_token, digest(token))

    def test_session_survives_restart(self):
        self.redeem(self.issue().json['code'])
        token = self.browser.get_cookie('ntrnet_session').value
        restarted = create_app(self.url, 'http://localhost')
        try:
            browser = restarted.test_client()
            browser.set_cookie('ntrnet_session', token)
            self.assertIn('alice.ss13dp', browser.get('/').get_data(as_text=True))
        finally:
            restarted.extensions['ntrnet_engine'].dispose()

    def test_invalid_identity_and_client_selected_code_rejected(self):
        for ckey in ('Alice', "alice';--", '', 'guest123', 123):
            self.assertEqual(self.issue(ckey).status_code, 400)
        self.assertEqual(self.browser.post('/api/v1/device/new', json={'ckey': 'alice', 'code': 'chosen'},
                                          headers={'X-Server-Key': 'a' * 43}).status_code, 400)

    def test_headers_errors_and_payload_limits(self):
        for path in ('/', '/missing', '/api/v1/catalog'):
            response = self.browser.get(path)
            self.assertEqual(response.headers['Cache-Control'], 'no-store')
            self.assertEqual(response.headers['X-Robots-Tag'], 'noindex, nofollow')
            self.assertEqual(response.headers['Referrer-Policy'], 'same-origin')
            self.assertIn("frame-ancestors 'none'", response.headers['Content-Security-Policy'])
        self.assertEqual(self.issue('a' * 5000).status_code, 413)
        self.assertEqual(self.browser.get('/', headers={'Host': 'evil.example'}).status_code, 400)

    def test_production_cookie_flags(self):
        if self.engine.dialect.name == 'sqlite':
            self.skipTest('Production requires MariaDB')
        production = create_app(self.url, 'https://ntrnet.example')
        try:
            browser = production.test_client()
            page = browser.get('/', base_url='https://ntrnet.example')
            csrf = re.search(r'name="csrf" value="([^"]+)"', page.get_data(as_text=True))[1]
            response = browser.post('/login', base_url='https://ntrnet.example',
                                    headers={'Origin': 'https://ntrnet.example'},
                                    data={'code': self.issue().json['code'], 'csrf': csrf})
            self.assertEqual(response.status_code, 303)
            for result, name in ((page, '__Host-ntrnet_csrf'), (response, '__Host-ntrnet_session')):
                cookie = result.headers['Set-Cookie']
                self.assertTrue(cookie.startswith(name + '='))
                for flag in ('Secure', 'HttpOnly', 'Path=/', 'SameSite=Strict'):
                    self.assertIn(flag, cookie)
                self.assertNotIn('Domain=', cookie)
            self.assertIn('alice.ss13dp', browser.get('/', base_url='https://ntrnet.example').get_data(as_text=True))
        finally:
            production.extensions['ntrnet_engine'].dispose()


if __name__ == '__main__':
    unittest.main()
