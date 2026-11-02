import { type Antagonist, Category } from '../base';

const TerrorSpider: Antagonist = {
  key: 'terrorspider',
  name: 'Паук Ужаса',
  description: [
    `Смертоносные пауки заполоняют станцию.`,
    `Плетите паутину, размножайтесь и уничтожьте экипаж.`,
  ],
  category: Category.Midround,
};

export default TerrorSpider;
