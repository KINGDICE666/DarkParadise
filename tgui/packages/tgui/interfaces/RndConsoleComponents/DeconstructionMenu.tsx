import {
  Box,
  Button,
  DmIcon,
  LabeledList,
  Section,
} from 'tgui-core/components';
import { useBackend } from '../../backend';

type DeconstructionData = {
  loaded_item: DeconstructedItem;
  destroy_queue: { id: string; name: string }[];
  destroy_busy: boolean;
} & RndData;

type DeconstructedItem = {
  name: string;
  origin_tech: DeconstructedTech[];
  icon: string;
  icon_state: string;
};

type DeconstructedTech = {
  name: string;
  object_level: number;
  current_level: number;
};

export const DeconstructionMenu = (properties) => {
  const { data, act } = useBackend<DeconstructionData>();

  const {
    loaded_item,
    linked_destroy,
    destroy_queue = [],
    destroy_busy,
  } = data;
  const has_queue = destroy_queue.length > 1;

  if (!linked_destroy) {
    return <Box>ДЕСТРУКТИВНЫЙ АНАЛИЗАТОР НЕ ПОДКЛЮЧЁН</Box>;
  }

  if (!loaded_item) {
    return (
      <Section title="Меню разборки">
        <b>Камера разборки пуста.</b>
      </Section>
    );
  }

  return (
    <Section noTopPadding title="Меню разборки">
      {has_queue && (
        <Box mt="10px">
          <h3>Очередь разборки:</h3>
          <LabeledList>
            {destroy_queue.map((item, index) => (
              <LabeledList.Item label={`${index + 1}`} key={item.id}>
                {item.name}
              </LabeledList.Item>
            ))}
          </LabeledList>
        </Box>
      )}
      <Box mt="10px">
        <DmIcon
          icon={loaded_item.icon}
          icon_state={loaded_item.icon_state}
          style={{
            verticalAlign: 'middle',
            width: '64px',
            margin: '0px',
            marginLeft: '0px',
          }}
        />
        {loaded_item.name}
      </Box>
      <Box mt="10px">
        <h3>Технологический потенциал:</h3>
      </Box>
      <LabeledList>
        {loaded_item.origin_tech.map((item) => {
          return (
            <LabeledList.Item label={`- ${item.name}`} key={item.name}>
              {item.object_level}{' '}
              {item.current_level ? (
                <>(На текущий момент: {item.current_level})</>
              ) : null}
            </LabeledList.Item>
          );
        })}
      </LabeledList>
      <Box mt="10px">
        <h3>Опции:</h3>
      </Box>
      <Button
        icon="unlink"
        disabled={destroy_busy}
        onClick={() => {
          act('deconstruct');
        }}
      >
        {has_queue ? 'Разобрать очередь' : 'Разобрать объект'}
      </Button>
      <Button
        icon="eject"
        disabled={destroy_busy}
        onClick={() => {
          act('eject_item');
        }}
      >
        {has_queue ? 'Извлечь первый предмет' : 'Извлечь объект'}
      </Button>
    </Section>
  );
};
