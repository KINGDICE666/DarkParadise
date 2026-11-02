import { type Antagonist, Category } from '../base';

const Abductor: Antagonist = {
  key: 'abductor',
  name: 'Абдуктор',
  description: [
    `Инопланетные учёные прибыли изучать людей.`,
    `Вдвоём похищайте членов экипажа и проводите над ними эксперименты.`,
  ],
  category: Category.Roundstart,
};

export default Abductor;
