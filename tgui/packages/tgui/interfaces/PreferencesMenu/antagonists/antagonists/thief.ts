import { type Antagonist, Category } from '../base';

const Thief: Antagonist = {
  key: 'thief',
  name: 'Вор',
  description: [
    `Гильдия воров ждёт добычи, а на станции полно ценностей, которые плохо лежат.`,
    `Украдите заданные предметы и не попадитесь службе безопасности.`,
  ],
  category: Category.Roundstart,
};

export default Thief;
