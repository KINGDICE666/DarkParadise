import { type Antagonist, Category } from '../base';

const Zombie: Antagonist = {
  key: 'zombie',
  name: 'Зомби',
  description: [
    `Нулевой пациент: в вашей крови дремлет некротическая чума.`,
    `Выберите момент, обратитесь и заразите как можно больше членов экипажа.`,
    `Призраком вы также можете занимать тела безмозглых зомби.`,
  ],
  category: Category.Roundstart,
};

export default Zombie;
