import unittest

from content import ContentError, compile_page, render_tree, source_from_tree


class ContentTests(unittest.TestCase):
    def test_compiles_supported_html_and_css(self):
        tree = compile_page(
            '<h1 id="title">Hello</h1><p class="note">Safe <strong>page</strong></p>',
            'h1 { color: #74e3bc; } .note { text-align: center; padding: 4px 8px; }',
        )
        self.assertEqual(tree['children'][0]['style']['color'], '#74e3bc')
        self.assertEqual(tree['children'][1]['style']['textAlign'], 'center')
        self.assertEqual(tree['children'][1]['children'][1]['type'], 'strong')

    def test_rejects_executable_or_external_content(self):
        bad_html = (
            '<script>alert(1)</script>',
            '<iframe src="https://evil.example"></iframe>',
            '<p onclick="alert(1)">bad</p>',
            '<p style="color:red">bad</p>',
            '<a href="https://evil.example">bad</a>',
            '<a href="byond://?src=admin">bad</a>',
            '<img src="https://evil.example/track.png">',
        )
        for source in bad_html:
            with self.subTest(source=source), self.assertRaises(ContentError):
                compile_page(source, '')
        for css in ('p { background: red; }', 'p { color: url(https://evil.example); }',
                    '@import "https://evil.example";', 'p > strong { color: red; }'):
            with self.subTest(css=css), self.assertRaises(ContentError):
                compile_page('<p>bad</p>', css)

    def test_internal_links_and_media_are_structured(self):
        site_id = 'a' * 32
        media = [dict(id='deadbeefdeadbeef', content_type='image/png',
                      url=f'https://media.wiki-ss13.space/{site_id}/deadbeefdeadbeef.png')]
        tree = compile_page(
            f'<a href="/{site_id}/index">Go</a><img data-media="deadbeefdeadbeef" alt="station">',
            '', media,
        )
        self.assertEqual(tree['children'][0]['type'], 'link')
        self.assertEqual(tree['children'][1]['type'], 'image')
        self.assertNotIn('href', tree['children'][0])

    def test_preview_escapes_text(self):
        rendered = render_tree(compile_page('<p>&lt;script&gt;safe text&lt;/script&gt;</p>', ''))
        self.assertIn('&lt;script&gt;', rendered)
        self.assertNotIn('<script>', rendered)
        unsafe = render_tree({'type': 'image', 'src': 'https://evil.example/track.png',
                              'style': {'color': 'red;position:fixed'}})
        self.assertEqual(unsafe, '')

    def test_legacy_tree_becomes_editable_source(self):
        tree = {'type': 'div', 'children': [
            {'type': 'p', 'children': [{'type': 'text', 'text': '<old page>'}]},
            {'type': 'link', 'site_id': 'welcome', 'slug': 'index',
             'children': [{'type': 'text', 'text': 'Open'}]},
        ]}
        source = source_from_tree(tree)
        self.assertIn('&lt;old page&gt;', source)
        rebuilt = compile_page(source, '')
        self.assertEqual(rebuilt['children'][0]['children'][1]['site_id'], 'welcome')

    def test_limits_depth_and_nodes(self):
        with self.assertRaises(ContentError):
            compile_page('<div>' * 20 + 'x' + '</div>' * 20, '')
        with self.assertRaises(ContentError):
            compile_page('<br>' * 1100, '')


if __name__ == '__main__':
    unittest.main()
