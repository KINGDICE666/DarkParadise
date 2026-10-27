import { afterEach, expect, test } from 'bun:test';
import { createElement } from 'react';
import { renderToStaticMarkup } from 'react-dom/server.node';
import { gameDataAtom, resetStore, store } from '../events/store';
import { Bioprinter } from '../interfaces/Bioprinter';

const render = (printing: 0 | 1) => {
  Byond.iconRefMap = { surgery: '/assets/surgery.dmi' };
  store.set(gameDataAtom, {
    biomass: 0,
    capacity: 200,
    selected_species: 'Human',
    species: [{ id: 'Human', name: 'Человек' }],
    products: [
      {
        slot: 'heart',
        name: 'Сердце человека',
        cost: 30,
        icon: 'surgery',
        icon_state: 'heart-on',
      },
      {
        slot: 'lungs',
        name: 'Лёгкие человека',
        cost: 20,
        icon: 'surgery',
        icon_state: 'lungs',
      },
    ],
    printing,
    remaining: 15,
    available: 1,
  });
  return renderToStaticMarkup(createElement(Bioprinter));
};

afterEach(() => {
  resetStore();
  Byond.iconRefMap = {};
});

test('numeric idle state does not render a stray zero', () => {
  const html = render(0);
  expect(html).not.toContain('>0<');
  expect(html).not.toContain('Идёт печать');
});

test('numeric active state displays the printing notice', () => {
  expect(render(1)).toContain('Идёт печать. Осталось 15 сек.');
});

test('shows the translated species and each organ sprite', () => {
  const html = render(0);
  expect(html).toContain('Человек');
  expect(html).not.toContain('>Human<');
  expect(html).toContain('/assets/surgery.dmi?state=heart-on');
  expect(html).toContain('/assets/surgery.dmi?state=lungs');
});
