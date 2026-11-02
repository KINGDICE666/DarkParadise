import { type Antagonist, Category } from '../base';

const GiantSpider: Antagonist = {
  key: 'giantspider',
  name: 'Гигантский паук',
  description: [
    `Восьмилапый хищник плетёт свои сети.`,
    `Охраняйте гнездо и охотьтесь на экипаж.`,
  ],
  category: Category.Midround,
};

export default GiantSpider;
