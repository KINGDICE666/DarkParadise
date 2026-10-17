import { type Antagonist, Category } from '../base';

const Heretic: Antagonist = {
  key: 'heretic',
  name: 'Еретик',
  description: [
    `Забытые боги нашёптывают вам тайны Мансуса.`,
    `Ищите разломы реальности, проводите ритуалы и восходите по выбранному пути.`,
  ],
  category: Category.Roundstart,
};

export default Heretic;
