from io import BytesIO
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from storage import LocalMediaStore, MediaError


class LocalMediaStoreTests(unittest.TestCase):
    def test_upload_and_delete_stay_inside_configured_root(self):
        with tempfile.TemporaryDirectory() as temporary:
            with patch.dict(os.environ, {
                'NTRNET_MEDIA_ROOT': temporary,
                'NTRNET_MEDIA_URL': 'https://media.wiki-ss13.space',
            }, clear=False):
                store = LocalMediaStore()
            object_key = f'{"a" * 32}/{"b" * 16}.png'
            store.upload(BytesIO(b'checked image bytes'), object_key, 'image/png')
            target = Path(temporary, *object_key.split('/'))
            self.assertEqual(target.read_bytes(), b'checked image bytes')
            self.assertEqual(store.url(object_key), 'https://media.wiki-ss13.space/' + object_key)
            with self.assertRaises(MediaError):
                store.upload(BytesIO(b'bad'), '../outside.png', 'image/png')
            store.delete(object_key)
            self.assertFalse(target.exists())

    def test_relative_root_is_rejected(self):
        with patch.dict(os.environ, {
            'NTRNET_MEDIA_ROOT': 'relative/media',
            'NTRNET_MEDIA_URL': 'https://media.wiki-ss13.space',
        }, clear=False):
            with self.assertRaises(ValueError):
                LocalMediaStore()


if __name__ == '__main__':
    unittest.main()
