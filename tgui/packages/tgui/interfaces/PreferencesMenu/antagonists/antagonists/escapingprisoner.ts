import { type Antagonist, Category } from '../base';

const EscapingPrisoner: Antagonist = {
  key: 'escapingprisoner',
  name: 'Сбежавший заключённый',
  description: [
    `Вас держат в тюрьме станции, но у вас есть план побега.`,
    `Сбегите с объекта, пока не стало поздно. Только для роли заключённого.`,
  ],
  category: Category.Roundstart,
};

export default EscapingPrisoner;
