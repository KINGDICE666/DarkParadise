import { type Antagonist, Category } from '../base';

const Cultist: Antagonist = {
  key: 'cultist',
  name: 'Культист',
  description: [
    `Нар'Си, Геометр Крови, жаждет прийти в этот мир.`,
    `Обращайте экипаж в культ, чертите руны и призовите своё божество.`,
  ],
  category: Category.Roundstart,
};

export default Cultist;
