import { type Antagonist, Category } from '../base';

const Trader: Antagonist = {
  key: 'trader',
  name: 'Торговец',
  description: [
    `Вы прибыли на станцию, чтобы торговать.`,
    `Продавайте товары экипажу и заработайте.`,
  ],
  category: Category.Midround,
};

export default Trader;
