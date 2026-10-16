import { useState } from 'react';
import { Box, ImageButton, Section, Stack, Tabs } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

const ICON_BY_CATEGORY_NAME = {
  Pipes: 'grip-lines',
  Supply: 'wind',
  Scrubbers: 'filter',
  Devices: 'microchip',
  'Heat Exchange': 'thermometer-half',
  Insulated: 'temperature-low',
  Disposals: 'trash-alt',
  'Transit Tubes': 'bus',
} as const;

type Data = {
  categories: Category[];
};

type Category = {
  cat_name: string;
  recipes: Recipe[];
};

type Recipe = {
  pipe_name: string;
  pipe_id: number;
  icon: string;
  icon_state: string;
  dir: number;
};

const PipeTypeSection = (props) => {
  const { act, data } = useBackend<Data>();
  const { categories = [] } = data;
  const [categoryName, setCategoryName] = useState(categories[0]?.cat_name);
  const shownCategory =
    categories.find((category) => category.cat_name === categoryName) ||
    categories[0];

  return (
    <Section fill scrollable>
      <Tabs>
        {categories.map((category) => (
          <Tabs.Tab
            key={category.cat_name}
            icon={ICON_BY_CATEGORY_NAME[category.cat_name]}
            selected={category.cat_name === shownCategory.cat_name}
            onClick={() => setCategoryName(category.cat_name)}
          >
            {category.cat_name}
          </Tabs.Tab>
        ))}
      </Tabs>
      {shownCategory?.recipes.map((recipe) => (
        <ImageButton
          key={recipe.pipe_id}
          fluid
          mb={0.5}
          imageSize={32}
          dmIcon={recipe.icon}
          dmIconState={recipe.icon_state}
          dmDirection={recipe.dir}
          onClick={() => act('dispense', { pipe_id: recipe.pipe_id })}
        >
          <Box textAlign="left">{recipe.pipe_name}</Box>
        </ImageButton>
      ))}
    </Section>
  );
};

export const PipeDispenser = (props) => {
  return (
    <Window width={530} height={530}>
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item grow>
            <PipeTypeSection />
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
