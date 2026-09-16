import hmac
import json
import os
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from urllib.parse import unquote, urlsplit

FIXTURE = Path(__file__).with_name('sites.json')
MAX_PAGE_BYTES = 64 * 1024


def make_handler(server_key, fixture=FIXTURE):
    if not server_key:
        raise ValueError('NTRNET_SERVER_KEY is required')
    content = json.loads(fixture.read_text(encoding='utf-8'))
    sites = content['sites']
    catalog = {'sites': [
        {**{key: site[key] for key in ('id', 'domain', 'title', 'version')},
         'pages': [{'slug': page['slug'], 'title': page['title']} for page in site['pages']]}
        for site in sites if not site.get('hidden')
    ]}
    pages = {}
    for site in sites:
        if site.get('hidden'):
            continue
        for page in site['pages']:
            document = {**page, 'site_id': site['id'], 'version': site['version']}
            if len(json.dumps(document, ensure_ascii=False).encode('utf-8')) > MAX_PAGE_BYTES:
                raise ValueError('Page exceeds 64 KiB')
            pages[(site['id'], page['slug'])] = document

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            path = urlsplit(self.path).path
            if path == '/health':
                self.reply(200, {'status': 'ok', 'mode': 'stub'})
                return
            supplied = self.headers.get('X-Server-Key', '')
            if not hmac.compare_digest(supplied.encode('utf-8'), server_key.encode('utf-8')):
                self.reply(401, {'error': 'unauthorized'})
                return
            if path == '/api/v1/catalog':
                self.reply(200, catalog)
                return
            if path == '/api/v1/zones':
                self.reply(200, {'zones': content['zones']})
                return
            parts = path.split('/')
            if len(parts) == 7 and parts[1:4] == ['api', 'v1', 'sites'] and parts[5] == 'pages':
                page = pages.get((unquote(parts[4]), unquote(parts[6])))
                if page:
                    self.reply(200, page)
                    return
            self.reply(404, {'error': 'not_found'})

        def reply(self, status, document):
            body = json.dumps(document, ensure_ascii=False).encode('utf-8')
            self.send_response(status)
            self.send_header('Content-Type', 'application/json; charset=utf-8')
            self.send_header('Content-Length', str(len(body)))
            self.send_header('Cache-Control', 'no-store')
            self.send_header('X-Robots-Tag', 'noindex, nofollow')
            self.send_header('X-Content-Type-Options', 'nosniff')
            self.end_headers()
            self.wfile.write(body)

        def log_message(self, *_args):
            pass

    return Handler


if __name__ == '__main__':
    handler = make_handler(os.environ.get('NTRNET_SERVER_KEY'))
    with HTTPServer(('127.0.0.1', int(os.environ.get('NTRNET_PORT', '8091'))), handler) as server:
        print('NTrnet development stub listening on', server.server_address, flush=True)
        server.serve_forever()
