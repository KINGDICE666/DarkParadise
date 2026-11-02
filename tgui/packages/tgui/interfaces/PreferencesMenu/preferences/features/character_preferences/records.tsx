import { type Feature, FeatureTextAreaInput } from '../base';

export const flavor_text: Feature<string> = {
  name: 'Описание внешности',
  component: FeatureTextAreaInput,
};

export const med_record: Feature<string> = {
  name: 'Медицинские записи',
  component: FeatureTextAreaInput,
};

export const sec_record: Feature<string> = {
  name: 'Записи службы безопасности',
  component: FeatureTextAreaInput,
};

export const gen_record: Feature<string> = {
  name: 'Записи отдела кадров',
  component: FeatureTextAreaInput,
};

export const exploit_record: Feature<string> = {
  name: 'Компрометирующая информация',
  component: FeatureTextAreaInput,
};

export const OOC_Notes: Feature<string> = {
  name: 'OOC-заметки',
  component: FeatureTextAreaInput,
};
