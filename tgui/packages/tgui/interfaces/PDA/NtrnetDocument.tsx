import { createElement, ReactNode } from 'react';
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
      (node.type !== 'link' && !TAGS.has(node.type))
    ) {
      return null;
    }
    if (node.type === 'br' || node.type === 'hr') {
      return createElement(node.type, { key });
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
        <Button key={key} onClick={() => onNavigate(siteId, slug)}>
          {children}
        </Button>
      );
    }
    return createElement(node.type, { key }, children);
  };
  return (
    <div style={{ overflowWrap: 'anywhere', whiteSpace: 'pre-wrap' }}>
      {render(tree, 0, 'root')}
    </div>
  );
};
