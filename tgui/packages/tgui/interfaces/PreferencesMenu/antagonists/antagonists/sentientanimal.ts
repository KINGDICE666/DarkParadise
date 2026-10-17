import { type Antagonist, Category } from '../base';

const SentientAnimal: Antagonist = {
  key: 'sentientanimal',
  name: 'Разумное животное',
  description: [
    `Вы — животное, обретшее разум.`,
    `Служите тому, кто дал вам разум.`,
  ],
  category: Category.Midround,
};

export default SentientAnimal;
