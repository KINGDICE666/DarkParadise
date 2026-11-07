import { afterEach, beforeEach, describe, expect, spyOn, test } from 'bun:test';
import { fireEvent, render, waitFor } from '@testing-library/react';

import * as actions from '../events/act';
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
        })),
      },
      {
        name: 'Предметы',
        items: [{ path: '/obj/item/camera', name: 'Camera' }],
      },
    ],
    selected_item: null,
    pixel_positioning: false,
    build_dir: 2,
    preview_icons: {},
  });
});

afterEach(() => {
  previewRequests.mockRestore();
});

let previewRequests: ReturnType<typeof spyOn<typeof actions, 'sendAct'>>;

beforeEach(() => {
  previewRequests = spyOn(actions, 'sendAct');
});

describe('BuildMode catalog', () => {
  test('requests only the visible page and coalesces quick page changes', async () => {
    const view = render(<BuildMode />);
    await waitFor(() => expect(previewRequests).toHaveBeenCalledTimes(1));
    const [action, payload] = previewRequests.mock.calls[0];
    expect(action).toBe('request_previews');
    expect(payload?.paths).toEqual(
      Array.from(
        { length: 96 },
        (_, index) => `/obj/structure/fixture_${index}`,
      ),
    );
    previewRequests.mockClear();
    fireEvent.click(view.getByText('Далее'));
    fireEvent.click(view.getByText('Предметы'));
    await waitFor(() => expect(previewRequests).toHaveBeenCalledTimes(1));
    expect(previewRequests).toHaveBeenCalledWith('request_previews', {
      paths: ['/obj/item/camera'],
    });
  });

  test('requests filtered results and releases previews on an empty search', async () => {
    const view = render(<BuildMode />);
    const search = view.getByPlaceholderText('Поиск по имени или пути типа...');
    fireEvent.input(search, { target: { value: 'fixture_12' } });
    await waitFor(() => expect(previewRequests).toHaveBeenCalledTimes(1));
    expect(previewRequests).toHaveBeenCalledWith('request_previews', {
      paths: ['/obj/structure/fixture_12'],
    });
    previewRequests.mockClear();
    fireEvent.input(search, { target: { value: 'no_matching_type' } });
    await waitFor(() => expect(previewRequests).toHaveBeenCalledTimes(1));
    expect(previewRequests).toHaveBeenCalledWith('request_previews', {
      paths: [],
    });
  });

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
