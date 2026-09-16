import http.client
import json
import threading
import unittest
from http.server import HTTPServer

from stub import make_handler


class StubTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = HTTPServer(('127.0.0.1', 0), make_handler('test-key'))
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join()

    def get(self, path, key='test-key'):
        connection = http.client.HTTPConnection(*self.server.server_address, timeout=3)
        connection.request('GET', path, headers={'X-Server-Key': key})
        response = connection.getresponse()
        body = json.loads(response.read())
        result = response.status, dict(response.getheaders()), body
        connection.close()
        return result

    def test_catalog_requires_key(self):
        for key in ('', 'wrong-key'):
            status, _, body = self.get('/api/v1/catalog', key)
            self.assertEqual(status, 401)
            self.assertNotIn('sites', body)

    def test_catalog_links_resolve(self):
        status, headers, catalog = self.get('/api/v1/catalog')
        self.assertEqual(status, 200)
        self.assertEqual(headers['X-Robots-Tag'], 'noindex, nofollow')
        self.assertEqual(headers['Cache-Control'], 'no-store')
        for site in catalog['sites']:
            for entry in site['pages']:
                status, _, page = self.get(f"/api/v1/sites/{site['id']}/pages/{entry['slug']}")
                self.assertEqual(status, 200)
                self.assertEqual(page['version'], site['version'])
                self.assertEqual(page['site_id'], site['id'])
                self.assertIsInstance(page['tree'], dict)

    def test_zones_exist(self):
        _, _, body = self.get('/api/v1/zones')
        zones = {zone['name']: zone for zone in body['zones']}
        self.assertIsNone(zones['ss13']['server_id'])
        self.assertEqual(zones['ss13dp']['server_id'], 'dark-paradise')

    def test_unknown_and_traversal_paths(self):
        for path in ('/', '/sites', '/api/v1/sites/welcome/pages/missing', '/api/v1/sites/..%2F..%2F/pages/index'):
            self.assertEqual(self.get(path)[0], 404)

    def test_page_requires_key(self):
        self.assertEqual(self.get('/api/v1/sites/welcome/pages/index', '')[0], 401)

    def test_no_default_secret(self):
        with self.assertRaises(ValueError):
            make_handler('')


if __name__ == '__main__':
    unittest.main()
