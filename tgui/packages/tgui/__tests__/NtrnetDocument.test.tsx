import { createElement } from 'react';
import { renderToStaticMarkup } from 'react-dom/server.node';
import { NtrnetDocument } from '../interfaces/PDA/NtrnetDocument';

const render = (tree: unknown) =>
  renderToStaticMarkup(
    createElement(NtrnetDocument, { tree, onNavigate: () => {} })
  );

test('renders text as text, without interpreting HTML', () => {
  const html = render({
    type: 'text',
    text: '<img src="https://evil.example/track" onerror="alert(1)">',
  });
  expect(html).toContain('&lt;img');
  expect(html).not.toContain('<img');
});

test('discards executable, external and unknown elements', () => {
  for (const type of [
    'script',
    'iframe',
    'img',
    'video',
    'a',
    'style',
    'object',
    'future-block',
  ]) {
    const html = render({
      type,
      href: 'byond://?src=admin',
      src: 'https://evil.example/',
      children: [{ type: 'text', text: 'unsafe-child' }],
    });
    expect(html).not.toContain('unsafe-child');
    expect(html).not.toContain('byond:');
    expect(html).not.toContain('evil.example');
  }
});

test('does not spread untrusted attributes onto allowed tags', () => {
  const html = render({
    type: 'p',
    onClick: 'alert(1)',
    style: { backgroundImage: 'url(https://evil.example)' },
    dangerouslySetInnerHTML: { __html: '<script>bad</script>' },
    children: [{ type: 'strong', children: [{ type: 'text', text: 'safe' }] }],
  });
  expect(html).toContain('<p><strong>safe</strong></p>');
  expect(html).not.toContain('evil.example');
  expect(html).not.toContain('<script>');
});

test('bounds tree depth and total node count', () => {
  let tree: unknown = { type: 'text', text: 'too-deep' };
  for (let index = 0; index < 100; index++) {
    tree = { type: 'div', children: [tree] };
  }
  expect(render(tree)).not.toContain('too-deep');
  const wide = render({
    type: 'div',
    children: Array.from({ length: 5000 }, () => ({ type: 'text', text: 'x' })),
  });
  expect(wide.length).toBeLessThan(1200);
});

test('ignores malformed nodes', () => {
  for (const tree of [
    null,
    false,
    42,
    [],
    { type: 'text', text: {} },
    { type: 'p', children: 'not-an-array' },
  ]) {
    expect(() => render(tree)).not.toThrow();
  }
});

test('internal links never become browser navigation', () => {
  const html = render({
    type: 'link',
    site_id: 'welcome',
    slug: 'index',
    href: 'byond://?src=admin',
    children: [{ type: 'text', text: 'Open site' }],
  });
  expect(html).toContain('Open site');
  expect(html).not.toContain('href');
  expect(html).not.toContain('byond:');
});

test('allows only explicit safe styles', () => {
  const html = render({
    type: 'p',
    style: {
      color: '#74e3bc',
      textAlign: 'center',
      backgroundImage: 'url(https://evil.example)',
      width: 'calc(100%)',
    },
    children: [{ type: 'text', text: 'styled' }],
  });
  expect(html).toContain('color:#74e3bc');
  expect(html).toContain('text-align:center');
  expect(html).not.toContain('evil.example');
  expect(html).not.toContain('calc');
});

test('renders media only from the NTrnet bucket', () => {
  const good = render({
    type: 'image',
    src: 'https://media.wiki-ss13.space/0123456789abcdef0123456789abcdef/0123456789abcdef.png',
    alt: '<station>',
  });
  expect(good).toContain('<img');
  expect(good).toContain('&lt;station&gt;');
  const bad = render({ type: 'video', src: 'https://evil.example/track.mp4' });
  expect(bad).not.toContain('<video');
  expect(bad).not.toContain('evil.example');
});
