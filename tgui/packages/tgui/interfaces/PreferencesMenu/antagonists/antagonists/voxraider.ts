import { type Antagonist, Category } from '../base';

const VoxRaider: Antagonist = {
  key: 'voxraider',
  name: 'Рейдер воксов',
  description: [
    `Воксы прилетели за добычей.`,
    `Вместе с командой ограбьте станцию.`,
  ],
  category: Category.Midround,
};

export default VoxRaider;
