import { beforeEach, describe, expect, test } from 'bun:test';
import { fireEvent, render } from '@testing-library/react';

import { gameDataAtom, resetStore, store } from '../events/store';
import { BuildMode } from '../interfaces/BuildMode';

beforeEach(() => {
  resetStore();
  store.set(gameDataAtom, {
    categories: [
      {
        name: 'Объекты',
        items: Array.from({ length: 100 }, (_, index) => ({
          path: `/obj/structure/fixture_${index}`,
          name: `Object ${index}`,
          icon: `bm_${index}`,
        })),
      },
      {
        name: 'Предметы',
        items: [
          { path: '/obj/item/camera', name: 'Camera', icon: 'bm_camera' },
        ],
      },
    ],
    selected_item: null,
    pixel_positioning: false,
    build_dir: 2,
  });
});

describe('BuildMode catalog', () => {
  test('limits the visible page and resets it when switching categories', () => {
    const view = render(<BuildMode />);
    expect(view.queryByText('Object 95')).not.toBeNull();
    expect(view.queryByText('Object 96')).toBeNull();
    fireEvent.click(view.getByText('Далее'));
    expect(view.queryByText('Object 0')).toBeNull();
    expect(view.queryByText('Object 99')).not.toBeNull();
    fireEvent.click(view.getByText('Предметы'));
    expect(view.queryByText('Camera')).not.toBeNull();
    expect(view.queryByText('Object 99')).toBeNull();
  });

  test('searches type paths after moving to another page', () => {
    const view = render(<BuildMode />);
    fireEvent.click(view.getByText('Далее'));
    const search = view.getByPlaceholderText('Поиск по имени или пути типа...');
    fireEvent.input(search, { target: { value: 'fixture_12' } });
    expect(view.queryByText('Object 12')).not.toBeNull();
    expect(view.queryByText('Object 99')).toBeNull();
  });
});
