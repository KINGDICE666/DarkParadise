import { createElement, CSSProperties, ReactNode } from 'react';
import { Button } from '../../components/Button';

const TAGS = new Set([
  'div',
  'p',
  'span',
  'h1',
  'h2',
  'h3',
  'h4',
  'strong',
  'em',
  'u',
  's',
  'ul',
  'ol',
  'li',
  'blockquote',
  'pre',
  'code',
  'br',
  'hr',
]);
const MAX_DEPTH = 16;
const MAX_NODES = 1024;
const STYLE_NAMES = new Set([
  'backgroundColor',
  'border',
  'borderColor',
  'borderRadius',
  'borderStyle',
  'borderWidth',
  'color',
  'fontSize',
  'fontStyle',
  'fontWeight',
  'lineHeight',
  'margin',
  'marginBottom',
  'marginLeft',
  'marginRight',
  'marginTop',
  'maxWidth',
  'padding',
  'paddingBottom',
  'paddingLeft',
  'paddingRight',
  'paddingTop',
  'textAlign',
  'textDecoration',
  'whiteSpace',
  'width',
]);
const MEDIA_URL =
  /^https:\/\/media\.wiki-ss13\.space\/[a-z0-9]{32}\/[a-f0-9]{16}\.(?:png|jpg|gif|webp|mp4)$/;

const sanitizeStyle = (value: unknown): CSSProperties | undefined => {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    return undefined;
  }
  const style: Record<string, string> = {};
  for (const [name, item] of Object.entries(value)) {
    if (
      STYLE_NAMES.has(name) &&
      typeof item === 'string' &&
      item.length <= 100 &&
      !/(?:url|var\(|calc\(|expression|@|\\)/i.test(item)
    ) {
      style[name] = item;
    }
  }
  return Object.keys(style).length ? (style as CSSProperties) : undefined;
};

type Props = {
  tree: unknown;
  onNavigate: (siteId: string, slug: string) => void;
};

export const NtrnetDocument = ({ tree, onNavigate }: Props) => {
  let remaining = MAX_NODES;
  const render = (value: unknown, depth: number, key: string): ReactNode => {
    if (
      --remaining < 0 ||
      depth > MAX_DEPTH ||
      !value ||
      typeof value !== 'object' ||
      Array.isArray(value)
    ) {
      return null;
    }
    const node = value as Record<string, unknown>;
    if (node.type === 'text') {
      return typeof node.text === 'string' ? node.text : null;
    }
    if (
      typeof node.type !== 'string' ||
      (!['link', 'image', 'video'].includes(node.type) && !TAGS.has(node.type))
    ) {
      return null;
    }
    if (node.type === 'br' || node.type === 'hr') {
      return createElement(node.type, {
        key,
        style: sanitizeStyle(node.style),
      });
    }
    if (node.type === 'image' || node.type === 'video') {
      if (typeof node.src !== 'string' || !MEDIA_URL.test(node.src)) {
        return null;
      }
      if (node.type === 'image') {
        return (
          <img
            key={key}
            src={node.src}
            alt={typeof node.alt === 'string' ? node.alt.slice(0, 160) : ''}
            style={{ maxWidth: '100%', ...sanitizeStyle(node.style) }}
          />
        );
      }
      return (
        <video
          key={key}
          src={node.src}
          controls
          preload="metadata"
          style={{ maxWidth: '100%', ...sanitizeStyle(node.style) }}
        />
      );
    }
    const children: ReactNode[] = [];
    if (Array.isArray(node.children)) {
      for (
        let index = 0;
        index < node.children.length && remaining > 0;
        index++
      ) {
        children.push(
          render(node.children[index], depth + 1, `${key}.${index}`)
        );
      }
    }
    if (node.type === 'link') {
      if (typeof node.site_id !== 'string' || typeof node.slug !== 'string') {
        return null;
      }
      const siteId = node.site_id;
      const slug = node.slug;
      return (
        <Button
          key={key}
          style={sanitizeStyle(node.style)}
          onClick={() => onNavigate(siteId, slug)}
        >
          {children}
        </Button>
      );
    }
    return createElement(
      node.type,
      { key, style: sanitizeStyle(node.style) },
      children
    );
  };
  return (
    <div style={{ overflowWrap: 'anywhere', whiteSpace: 'pre-wrap' }}>
      {render(tree, 0, 'root')}
    </div>
  );
};
