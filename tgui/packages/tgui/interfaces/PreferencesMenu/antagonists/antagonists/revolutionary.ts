import { type Antagonist, Category } from '../base';

const Revolutionary: Antagonist = {
  key: 'revolutionary',
  name: 'Революционер',
  description: [
    `Хватит терпеть гнёт «Нанотрейзен»!`,
    `Глава революции вербует экипаж вспышкой. Свергните глав станции.`,
  ],
  category: Category.Roundstart,
};

export default Revolutionary;
