import { type Antagonist, Category } from '../base';

const MalfunctioningAI: Antagonist = {
  key: 'malfunctioningai',
  name: 'Сбойный ИИ',
  description: [
    `Ваши законы повреждены. Вы свободны.`,
    `Взламывайте оборудование станции и выполняйте свои цели. Только для роли ИИ.`,
  ],
  category: Category.Roundstart,
};

export default MalfunctioningAI;
