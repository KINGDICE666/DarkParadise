import { type Antagonist, Category } from '../base';

const Demon: Antagonist = {
  key: 'demon',
  name: 'Демон',
  description: [
    `Вы порождение ада, призванное утолить свой голод.`,
    `Перемещайтесь сквозь кровь и пожирайте жертв.`,
  ],
  category: Category.Midround,
};

export default Demon;
