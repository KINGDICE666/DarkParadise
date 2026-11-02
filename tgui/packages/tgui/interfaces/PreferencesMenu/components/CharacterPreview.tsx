import { useEffect, useRef } from 'react';
import { globalEvents } from 'tgui-core/events';
import { debounce } from 'tgui-core/timer';

import { useBackend } from '../../../backend';

const PREVIEW_RESIZE_DEBOUNCE = 100;
const PREVIEW_SETTLE_DELAY = 100;

export const CHARACTER_PREVIEW_HEIGHT = '355px';

let hideTimer: ReturnType<typeof setTimeout> | undefined;
let showTimer: ReturnType<typeof setTimeout> | undefined;
let previewShown = false;
let previewSize = '';
let previewPos = '';

export function destroyCharacterPreview(id: string) {
  clearTimeout(hideTimer);
  clearTimeout(showTimer);
  previewShown = false;
  previewSize = '';
  previewPos = '';
  Byond.winset(id, { parent: '' });
}

export const CharacterPreview = (props: { height: string; id: string }) => {
  const { act } = useBackend();
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const getSize = () => {
      const rect = ref.current?.getBoundingClientRect();
      const pixelRatio = window.devicePixelRatio ?? 1;
      return rect
        ? `${Math.round(rect.width * pixelRatio)}x${Math.round(rect.height * pixelRatio)}`
        : '';
    };

    const render = (visible: boolean) => {
      const element = ref.current;
      if (!element) {
        return;
      }

      const pixelRatio = window.devicePixelRatio ?? 1;
      const rect = element.getBoundingClientRect();
      const pos = `${Math.round(rect.left * pixelRatio)},${Math.round(rect.top * pixelRatio)}`;
      const size = getSize();
      if (visible && pos === previewPos && size === previewSize) {
        return;
      }
      previewPos = visible ? pos : '';
      previewSize = size;
      Byond.winset(props.id, {
        parent: Byond.windowId,
        type: 'map',
        'is-visible': visible,
        pos,
        size,
      });

      if (!previewShown) {
        previewShown = true;
        act('show_preview');
      }
    };

    const debouncedRender = debounce(
      () => render(true),
      PREVIEW_RESIZE_DEBOUNCE,
    );

    clearTimeout(hideTimer);
    clearTimeout(showTimer);
    window.addEventListener('resize', debouncedRender);
    globalEvents.on('window-geometry-finished', debouncedRender);

    if (previewShown && getSize() !== previewSize) {
      render(false);
      showTimer = setTimeout(
        () => Byond.winset(props.id, { 'is-visible': true }),
        PREVIEW_SETTLE_DELAY,
      );
    } else {
      render(true);
    }

    return () => {
      clearTimeout(showTimer);
      window.removeEventListener('resize', debouncedRender);
      globalEvents.off('window-geometry-finished', debouncedRender);
      hideTimer = setTimeout(() => {
        previewShown = false;
        previewPos = '';
        Byond.winset(props.id, { 'is-visible': false });
        act('hide_preview');
      });
    };
  }, [props.id]);

  return <div ref={ref} style={{ width: '220px', height: props.height }} />;
};
