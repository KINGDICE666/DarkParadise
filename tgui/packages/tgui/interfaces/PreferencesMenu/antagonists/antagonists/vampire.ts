import { type Antagonist, Category } from '../base';

const Vampire: Antagonist = {
  key: 'vampire',
  name: 'Вампир',
  description: [
    `Древнее проклятие сделало вас ночным хищником, жаждущим крови.`,
    `Пейте кровь экипажа, открывайте новые способности и избегайте святой воды.`,
  ],
  category: Category.Roundstart,
};

export default Vampire;
