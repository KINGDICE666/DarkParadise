import { type Antagonist, Category } from '../base';

const CorticalBorer: Antagonist = {
  key: 'corticalborer',
  name: 'Мозговой червь',
  description: [
    `Паразит, проникающий в мозг носителя.`,
    `Управляйте носителем и размножайтесь.`,
  ],
  category: Category.Midround,
};

export default CorticalBorer;
