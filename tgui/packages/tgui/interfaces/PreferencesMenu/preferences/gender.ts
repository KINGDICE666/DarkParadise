export enum Gender {
  Male = 'male',
  Female = 'female',
  Other = 'plural',
}

export const GENDERS = {
  [Gender.Male]: {
    icon: 'mars',
    text: 'Мужской',
  },

  [Gender.Female]: {
    icon: 'venus',
    text: 'Женский',
  },

  [Gender.Other]: {
    icon: 'transgender',
    text: 'Бесполый',
  },
};
