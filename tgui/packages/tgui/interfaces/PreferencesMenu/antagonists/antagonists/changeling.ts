import { type Antagonist, Category } from '../base';

const Changeling: Antagonist = {
  key: 'changeling',
  name: 'Генокрад',
  description: [
    `Инопланетный паразит, способный перенимать облик и голос других существ.`,
    `Поглощайте экипаж, чтобы копировать ДНК и получать новые способности, оставаясь неузнанным.`,
  ],
  category: Category.Roundstart,
};

export default Changeling;
