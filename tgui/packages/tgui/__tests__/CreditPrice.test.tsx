import { afterEach, expect, test } from 'bun:test';
import { createElement } from 'react';
import { renderToStaticMarkup } from 'react-dom/server.node';
import { configAtom, store } from '../events/store';
import { CreditPrice } from '../interfaces/common/CreditPrice';

const originalConfig = store.get(configAtom);

afterEach(() => store.set(configAtom, originalConfig));

const renderPrice = (value: number, freeLabel?: string) =>
  renderToStaticMarkup(createElement(CreditPrice, { value, freeLabel }));

test('credit prices keep their normal values without a hallucination', () => {
  store.set(configAtom, { ...originalConfig, credit_price_override: null });
  expect(renderPrice(25)).toBe('25');
  expect(renderPrice(0, 'БЕСПЛАТНО')).toBe('БЕСПЛАТНО');
});

test('hallucination overrides displayed prices including free products', () => {
  store.set(configAtom, { ...originalConfig, credit_price_override: 999 });
  expect(renderPrice(25)).toBe('999');
  expect(renderPrice(0)).toBe('999');
  expect(renderPrice(0, 'БЕСПЛАТНО')).toBe('999');
});

test('a regular config update restores the original price', () => {
  store.set(configAtom, { ...originalConfig, credit_price_override: 999 });
  expect(renderPrice(50)).toBe('999');
  store.set(configAtom, { ...originalConfig, credit_price_override: null });
  expect(renderPrice(50)).toBe('50');
});
