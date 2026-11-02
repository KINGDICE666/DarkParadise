import { type Antagonist, Category } from '../base';

const Traitor: Antagonist = {
  key: 'traitor',
  name: 'Предатель',
  description: [
    `Неоплаченный долг, старые счёты или просто неудачное стечение обстоятельств. Синдикат выбрал вас для работы на станции.`,
    `Получите аплинк, закупите снаряжение и выполните свои зловещие цели.`,
  ],
  category: Category.Roundstart,
  priority: -1,
};

export default Traitor;
