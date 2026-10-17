export type Antagonist = {
  key: string;
  name: string;
  description: string[];
  category: Category;
  priority?: number;
};

export enum Category {
  Roundstart,
  Midround,
  Latejoin,
}
