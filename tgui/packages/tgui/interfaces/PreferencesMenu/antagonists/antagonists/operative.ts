import { type Antagonist, Category } from '../base';

const Operative: Antagonist = {
  key: 'operative',
  name: 'Ядерный оперативник',
  description: [
    `Синдикат отправил элитный отряд, чтобы стереть станцию с лица галактики.`,
    `Вместе с командой захватите диск ядерной аутентификации и взорвите станцию.`,
  ],
  category: Category.Roundstart,
};

export default Operative;
