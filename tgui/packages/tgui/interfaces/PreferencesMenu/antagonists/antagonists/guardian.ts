import { type Antagonist, Category } from '../base';

const Guardian: Antagonist = {
  key: 'guardian',
  name: 'Страж',
  description: [
    `Вы — дух-защитник, привязанный к своему хозяину.`,
    `Служите хозяину и защищайте его любой ценой.`,
  ],
  category: Category.Midround,
};

export default Guardian;
