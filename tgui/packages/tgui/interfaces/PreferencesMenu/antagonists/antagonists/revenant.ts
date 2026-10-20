import { type Antagonist, Category } from '../base';

const Revenant: Antagonist = {
  key: 'revenant',
  name: 'Ревенант',
  description: [
    `Мстительный дух, питающийся эссенцией мёртвых.`,
    `Собирайте эссенцию трупов и сейте хаос.`,
  ],
  category: Category.Midround,
};

export default Revenant;
