import { useEffect, useState } from 'react';
import {
  Box,
  Button,
  Dropdown,
  Input,
  NumberInput,
  Stack,
  TextArea,
} from 'tgui-core/components';

import { useBackend } from '../../backend';
import {
  type ChoicedServerData,
  createSetPreference,
  type NumericServerData,
  type PreferencesMenuData,
} from './types';
import { useServerPrefs } from './useServerPrefs';

type FeatureKind =
  | 'dropdown'
  | 'color'
  | 'number'
  | 'toggle'
  | 'text'
  | 'textarea'
  | 'skin_tone';

export type Feature = {
  name: string;
  kind: FeatureKind;
  category?: string;
  description?: string;
};

const INTERFACE = 'Интерфейс';
const GRAPHICS = 'Графика';
const GHOST = 'Призрак';
const ADMIN = 'Администрация';

export const features: Record<string, Feature> = {
  real_name: { name: 'Имя', kind: 'text' },
  name_is_always_random: { name: 'Всегда случайное имя', kind: 'toggle' },
  species: { name: 'Раса', kind: 'dropdown' },
  gender: { name: 'Пол', kind: 'dropdown' },
  age: { name: 'Возраст', kind: 'number' },
  language: { name: 'Дополнительный язык', kind: 'dropdown' },
  autohiss: { name: 'Авто-акцент', kind: 'dropdown' },
  b_type: { name: 'Группа крови', kind: 'dropdown' },
  nanotrasen_relation: { name: 'Отношение к «Нанотрейзен»', kind: 'dropdown' },
  uplink_pref: { name: 'Местоположение аплинка', kind: 'dropdown' },
  exoframe_type: { name: 'Каркас экзоскелета', kind: 'dropdown' },
  speciesprefs: { name: 'Расовая особенность', kind: 'toggle' },
  can_be_antagonist: { name: 'Может быть антагонистом', kind: 'toggle' },
  backbag: { name: 'Рюкзак', kind: 'dropdown' },
  alternate_option: { name: 'Если должность недоступна', kind: 'dropdown' },

  hair_style_name: { name: 'Причёска', kind: 'dropdown' },
  hair_colour: { name: 'Цвет причёски', kind: 'color' },
  secondary_hair_colour: {
    name: 'Дополнительный цвет причёски',
    kind: 'color',
  },
  hair_gradient: { name: 'Градиент причёски', kind: 'dropdown' },
  hair_gradient_colour: { name: 'Цвет градиента', kind: 'color' },
  hair_gradient_alpha: { name: 'Прозрачность градиента', kind: 'number' },
  hair_gradient_offset_x: { name: 'Смещение градиента по X', kind: 'number' },
  hair_gradient_offset_y: { name: 'Смещение градиента по Y', kind: 'number' },
  facial_style_name: { name: 'Лицевая растительность', kind: 'dropdown' },
  facial_hair_colour: { name: 'Цвет лицевой растительности', kind: 'color' },
  secondary_facial_hair_colour: {
    name: 'Дополнительный цвет лицевой растительности',
    kind: 'color',
  },
  head_accessory_style_name: { name: 'Аксессуары на голове', kind: 'dropdown' },
  head_accessory_colour: { name: 'Цвет аксессуаров на голове', kind: 'color' },
  alt_head_name: { name: 'Тип головы', kind: 'dropdown' },
  head_marking_style: { name: 'Отметки на голове', kind: 'dropdown' },
  head_marking_colour: { name: 'Цвет отметок на голове', kind: 'color' },
  body_marking_style: { name: 'Отметки на теле', kind: 'dropdown' },
  body_marking_colour: { name: 'Цвет отметок на теле', kind: 'color' },
  tail_marking_style: { name: 'Отметки на хвосте', kind: 'dropdown' },
  tail_marking_colour: { name: 'Цвет отметок на хвосте', kind: 'color' },
  body_accessory: { name: 'Хвост', kind: 'dropdown' },
  skin_tone: { name: 'Тон кожи', kind: 'skin_tone' },
  skin_colour: { name: 'Цвет кожи', kind: 'color' },
  eye_colour: { name: 'Цвет глаз', kind: 'color' },
  underwear: { name: 'Нижнее бельё', kind: 'dropdown' },
  underwear_color: { name: 'Цвет нижнего белья', kind: 'color' },
  undershirt: { name: 'Нательная рубашка', kind: 'dropdown' },
  undershirt_color: { name: 'Цвет нательной рубашки', kind: 'color' },
  socks: { name: 'Носки', kind: 'dropdown' },

  flavor_text: { name: 'Описание внешности', kind: 'textarea' },
  med_record: { name: 'Медицинские записи', kind: 'textarea' },
  sec_record: { name: 'Записи службы безопасности', kind: 'textarea' },
  gen_record: { name: 'Записи отдела кадров', kind: 'textarea' },
  exploit_record: { name: 'Компрометирующая информация', kind: 'textarea' },
  OOC_Notes: { name: 'OOC-заметки', kind: 'textarea' },

  UI_style: { name: 'Стиль интерфейса', kind: 'dropdown', category: INTERFACE },
  UI_style_color: {
    name: 'Цвет интерфейса',
    kind: 'color',
    category: INTERFACE,
  },
  UI_style_alpha: {
    name: 'Прозрачность интерфейса',
    kind: 'number',
    category: INTERFACE,
  },
  screentip_mode: {
    name: 'Размер всплывающей подсказки',
    kind: 'number',
    category: INTERFACE,
    description: '0 — подсказки выключены. Рекомендуется от 8 до 15.',
  },
  screentip_color: {
    name: 'Цвет всплывающей подсказки',
    kind: 'color',
    category: INTERFACE,
  },
  achivements_sound: {
    name: 'Звук получения достижения',
    kind: 'dropdown',
    category: INTERFACE,
  },
  ooccolor: { name: 'Цвет OOC-сообщений', kind: 'color', category: ADMIN },
  atklog: {
    name: 'Отображение боевых сообщений',
    kind: 'dropdown',
    category: ADMIN,
  },
  clientfps: {
    name: 'FPS',
    kind: 'number',
    category: GRAPHICS,
    description:
      '0 — значение по умолчанию, -1 — синхронизация с сервером. 20/40/50 могут помочь при проблемах с плавностью.',
  },
  parallax: { name: 'Параллакс', kind: 'dropdown', category: GRAPHICS },
  multiz_detail: {
    name: 'Качество Multi-Z параллакса',
    kind: 'dropdown',
    category: GRAPHICS,
  },
  viewrange: { name: 'Диапазон обзора', kind: 'dropdown', category: GRAPHICS },
  zoom_mode: { name: 'Масштабирование', kind: 'dropdown', category: GRAPHICS },
  zoom: { name: 'Зум', kind: 'number', category: GRAPHICS },
  ghost_darkness_level: {
    name: 'Освещённость для призрака',
    kind: 'dropdown',
    category: GHOST,
  },
};

type FeatureInputProps = {
  featureId: string;
  value: unknown;
  shrink?: boolean;
};

function useChoices(featureId: string) {
  const { data } = useBackend<PreferencesMenuData>();
  const serverData = useServerPrefs()?.[featureId] as
    | ChoicedServerData
    | undefined;
  const choices =
    data.character_preferences.valid_choices?.[featureId] ||
    serverData?.choices ||
    [];
  const displayNames = serverData?.display_names || {};
  return choices.map((choice) => ({
    value: choice,
    displayText: displayNames[choice] || String(choice),
  }));
}

function DropdownInput(props: FeatureInputProps & { onSet: (v) => void }) {
  const options = useChoices(props.featureId);
  const selected = options.find((option) => option.value === props.value);
  const serverData = useServerPrefs()?.[props.featureId] as
    | ChoicedServerData
    | undefined;
  const icons = serverData?.icons;

  return (
    <Dropdown
      width="100%"
      buttons={!!icons}
      menuWidth={icons ? 'max-content' : undefined}
      selected={String(props.value)}
      displayText={selected?.displayText ?? String(props.value)}
      options={options.map((option) => ({
        displayText: icons?.[option.value] ? (
          <Stack>
            <Stack.Item>
              <Box
                className={`${serverData?.icon_sheet} ${icons[option.value]}`}
                style={{ transform: 'scale(0.8)' }}
              />
            </Stack.Item>
            <Stack.Item grow>{option.displayText}</Stack.Item>
          </Stack>
        ) : (
          option.displayText
        ),
        value: String(option.value),
      }))}
      onSelected={(value) => {
        const option = options.find((choice) => String(choice.value) === value);
        props.onSet(option ? option.value : value);
      }}
    />
  );
}

export function ColorInput(props: FeatureInputProps) {
  const { act } = useBackend<PreferencesMenuData>();
  const value = String(props.value || '#000000');

  return (
    <Button
      onClick={() =>
        act('set_color_preference', { preference: props.featureId })
      }
    >
      <Stack align="center" fill>
        <Stack.Item>
          <Box
            style={{
              background: value.startsWith('#') ? value : `#${value}`,
              border: '2px solid white',
              boxSizing: 'content-box',
              height: '11px',
              width: '11px',
            }}
          />
        </Stack.Item>
        {!props.shrink && <Stack.Item>Изменить</Stack.Item>}
      </Stack>
    </Button>
  );
}

function NumberFeatureInput(props: FeatureInputProps & { onSet: (v) => void }) {
  const { data } = useBackend<PreferencesMenuData>();
  const serverData = useServerPrefs()?.[props.featureId] as
    | NumericServerData
    | undefined;
  const range = data.character_preferences.valid_ranges?.[props.featureId];

  return (
    <NumberInput
      minValue={range?.[0] ?? serverData?.minimum ?? 0}
      maxValue={range?.[1] ?? serverData?.maximum ?? 100}
      step={serverData?.step || 1}
      value={Number(props.value) || 0}
      onChange={(value) => props.onSet(value)}
    />
  );
}

function SkinToneInput(props: FeatureInputProps & { onSet: (v) => void }) {
  const { data } = useBackend<PreferencesMenuData>();
  const serverPrefs = useServerPrefs();
  const species = data.character_preferences.manually_rendered_features
    .species as string;
  const toneNames = (
    serverPrefs?.skin_tone as { icon_tone_names?: Record<string, string[]> }
  )?.icon_tone_names?.[species];

  if (toneNames) {
    return (
      <Dropdown
        width="100%"
        selected={toneNames[Number(props.value) - 1] ?? String(props.value)}
        options={toneNames.map((name, index) => ({
          displayText: name,
          value: String(index + 1),
        }))}
        onSelected={(value) => props.onSet(Number(value))}
      />
    );
  }

  return <NumberFeatureInput {...props} />;
}

export function FeatureValueInput(props: FeatureInputProps) {
  const { act, data } = useBackend<PreferencesMenuData>();
  const feature = features[props.featureId];
  const [predicted, setPredicted] = useState(props.value);

  useEffect(() => {
    setPredicted(props.value);
  }, [data.active_slot, props.value]);

  const onSet = (value: unknown) => {
    setPredicted(value);
    createSetPreference(act, props.featureId)(value);
  };

  if (!feature) {
    return <Box color="bad">{props.featureId}</Box>;
  }

  switch (feature.kind) {
    case 'dropdown':
      return (
        <DropdownInput
          featureId={props.featureId}
          value={predicted}
          onSet={onSet}
        />
      );
    case 'color':
      return (
        <ColorInput
          featureId={props.featureId}
          value={props.value}
          shrink={props.shrink}
        />
      );
    case 'number':
      return (
        <NumberFeatureInput
          featureId={props.featureId}
          value={predicted}
          onSet={onSet}
        />
      );
    case 'skin_tone':
      return (
        <SkinToneInput
          featureId={props.featureId}
          value={predicted}
          onSet={onSet}
        />
      );
    case 'toggle':
      return (
        <Button.Checkbox
          checked={!!predicted}
          onClick={() => onSet(!predicted)}
        />
      );
    case 'text':
      return (
        <Input
          fluid
          value={String(predicted ?? '')}
          onBlur={(value) => onSet(value)}
        />
      );
    case 'textarea':
      return (
        <TextArea
          fluid
          height="6em"
          value={String(predicted ?? '')}
          onBlur={(value) => onSet(value)}
        />
      );
  }
}
