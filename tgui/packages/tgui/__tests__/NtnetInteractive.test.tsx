import { describe, expect, test } from 'bun:test';

import { isInteractive } from '../interfaces/PDA/NtnetInteractive';

const SITE = '0123456789abcdef0123456789abcdef';
const GOOD = `https://sandbox.wiki-ss13.space/i/${SITE}/index`;

describe('NTnet interactive address', () => {
  test('accepts only the sandbox origin', () => {
    expect(isInteractive({ url: GOOD, version: 1 })).toEqual({
      url: GOOD,
      version: 1,
    });
    expect(isInteractive({ url: GOOD })).toEqual({ url: GOOD, version: 1 });
  });

  test('refuses anything else', () => {
    for (const url of [
      `http://sandbox.wiki-ss13.space/i/${SITE}/index`,
      `https://ntnet.wiki-ss13.space/i/${SITE}/index`,
      `https://media.wiki-ss13.space/i/${SITE}/index`,
      `https://sandbox.wiki-ss13.space.evil.example/i/${SITE}/index`,
      `https://evil.example/i/${SITE}/index`,
      `https://sandbox.wiki-ss13.space@evil.example/i/${SITE}/index`,
      `https://sandbox.wiki-ss13.space/i/${SITE}/index?x=1`,
      `https://sandbox.wiki-ss13.space/i/${SITE}/index#x`,
      `https://sandbox.wiki-ss13.space/../i/${SITE}/index`,
      `https://sandbox.wiki-ss13.space/i/${SITE}/ИНДЕКС`,
      'https://sandbox.wiki-ss13.space/i/short/index',
      'javascript:alert(1)',
      'byond://?src=admin',
      'data:text/html,<script>alert(1)</script>',
      '',
    ]) {
      expect(isInteractive({ url, version: 1 })).toBeNull();
    }
  });

  test('refuses junk instead of an object', () => {
    for (const value of [null, undefined, 'x', 42, [], { version: 1 }]) {
      expect(isInteractive(value)).toBeNull();
    }
  });
});
