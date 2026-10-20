import { type Antagonist, Category } from '../base';

const Wizard: Antagonist = {
  key: 'wizard',
  name: 'Волшебник',
  description: [
    `Федерация Космических Волшебников отправила вас устроить хаос на станции.`,
    `Выберите заклинания из книги и выполните свои цели любой ценой.`,
  ],
  category: Category.Roundstart,
};

export default Wizard;
