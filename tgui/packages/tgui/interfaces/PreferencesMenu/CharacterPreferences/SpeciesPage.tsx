import { useBackend } from 'tgui/backend';
import {
  BlockQuote,
  Box,
  Button,
  Divider,
  Icon,
  Section,
  Stack,
  Tooltip,
} from 'tgui-core/components';
import { classes } from 'tgui-core/react';
import { LoadingScreen } from '../../common/LoadingScreen';
import { CharacterPreview } from '../components/CharacterPreview';
import {
  createSetPreference,
  Food,
  type Perk,
  type PreferencesMenuData,
  type ServerData,
  type Species,
} from '../types';
import { useServerPrefs } from '../useServerPrefs';

const FOOD_ICONS = {
  [Food.Bugs]: 'bug',
  [Food.Cloth]: 'tshirt',
  [Food.Dairy]: 'cheese',
  [Food.Fried]: 'bacon',
  [Food.Fruit]: 'apple-alt',
  [Food.Gore]: 'skull',
  [Food.Grain]: 'bread-slice',
  [Food.Gross]: 'trash',
  [Food.Junkfood]: 'pizza-slice',
  [Food.Meat]: 'hamburger',
  [Food.Nuts]: 'seedling',
  [Food.Raw]: 'drumstick-bite',
  [Food.Seafood]: 'fish',
  [Food.Stone]: 'gem',
  [Food.Sugar]: 'candy-cane',
  [Food.Toxic]: 'biohazard',
  [Food.Vegetables]: 'carrot',
};

const FOOD_NAMES: Record<keyof typeof FOOD_ICONS, string> = {
  [Food.Bugs]: 'Насекомые',
  [Food.Cloth]: 'Одежда',
  [Food.Dairy]: 'Молочное',
  [Food.Fried]: 'Жареное',
  [Food.Fruit]: 'Фрукты',
  [Food.Gore]: 'Кровавое',
  [Food.Grain]: 'Злаки',
  [Food.Gross]: 'Мерзость',
  [Food.Junkfood]: 'Фастфуд',
  [Food.Meat]: 'Мясо',
  [Food.Nuts]: 'Орехи',
  [Food.Raw]: 'Сырое',
  [Food.Seafood]: 'Морепродукты',
  [Food.Stone]: 'Камни',
  [Food.Sugar]: 'Сладкое',
  [Food.Toxic]: 'Ядовитое',
  [Food.Vegetables]: 'Овощи',
};

const IGNORE_UNLESS_LIKED: Set<Food> = new Set([
  Food.Bugs,
  Food.Cloth,
  Food.Gross,
  Food.Toxic,
]);

function notIn<T>(set: Set<T>) {
  return (value: T) => {
    return !set.has(value);
  };
}

type FoodListProps = {
  food: Food[];
  icon: string;
  name: string;
  className: string;
};

function FoodList(props: FoodListProps) {
  const { food = [], icon, name, className } = props;

  if (food.length === 0) {
    return null;
  }

  return (
    <Tooltip
      position="bottom-end"
      content={
        <Box>
          <Icon name={icon} /> <b>{name}</b>
          <Divider />
          <Box>
            {food
              .reduce((names, food) => {
                const foodName = FOOD_NAMES[food];
                return foodName ? names.concat(foodName) : names;
              }, [])
              .join(', ')}
          </Box>
        </Box>
      }
    >
      <Stack ml={2}>
        {food.map((food) => {
          return (
            FOOD_ICONS[food] && (
              <Stack.Item>
                <Icon
                  className={className}
                  size={1.4}
                  key={food}
                  name={FOOD_ICONS[food]}
                />
              </Stack.Item>
            )
          );
        })}
      </Stack>
    </Tooltip>
  );
}

type DietProps = {
  diet: Species['diet'];
};

function Diet(props: DietProps) {
  const { diet } = props;
  if (!diet) {
    return null;
  }

  const { liked_food, disliked_food, toxic_food } = diet;

  return (
    <Stack>
      <Stack.Item>
        <FoodList
          food={liked_food}
          icon="heart"
          name="Любимая еда"
          className="color-pink"
        />
      </Stack.Item>

      <Stack.Item>
        <FoodList
          food={disliked_food.filter(notIn(IGNORE_UNLESS_LIKED))}
          icon="thumbs-down"
          name="Нелюбимая еда"
          className="color-red"
        />
      </Stack.Item>

      <Stack.Item>
        <FoodList
          food={toxic_food.filter(notIn(IGNORE_UNLESS_LIKED))}
          icon="biohazard"
          name="Ядовитая еда"
          className="color-olive"
        />
      </Stack.Item>
    </Stack>
  );
}

type SpeciesPerkProps = {
  className: string;
  perk: Perk;
};

function SpeciesPerk(props: SpeciesPerkProps) {
  const { className, perk } = props;

  return (
    <Tooltip
      position="bottom-end"
      content={
        <Box>
          <Box as="b">{perk.name}</Box>
          <Divider />
          <Box>{perk.description}</Box>
        </Box>
      }
    >
      <Box className={className} width="32px" height="32px">
        <Icon
          name={perk.ui_icon}
          size={1.5}
          ml={0}
          mt={1}
          style={{
            textAlign: 'center',
            height: '100%',
            width: '100%',
          }}
        />
      </Box>
    </Tooltip>
  );
}

type SpeciesPerksProps = {
  perks: Species['perks'];
};

function SpeciesPerks(props: SpeciesPerksProps) {
  const { positive, negative, neutral } = props.perks;

  return (
    <Stack fill justify="space-between">
      <Stack.Item>
        <Stack>
          {positive.map((perk) => {
            return (
              <Stack.Item key={perk.name}>
                <SpeciesPerk className="color-bg-green" perk={perk} />
              </Stack.Item>
            );
          })}
        </Stack>
      </Stack.Item>

      <Stack>
        {neutral.map((perk) => {
          return (
            <Stack.Item key={perk.name}>
              <SpeciesPerk className="color-bg-grey" perk={perk} />
            </Stack.Item>
          );
        })}
      </Stack>

      <Stack>
        {negative.map((perk) => {
          return (
            <Stack.Item key={perk.name}>
              <SpeciesPerk className="color-bg-red" perk={perk} />
            </Stack.Item>
          );
        })}
      </Stack>
    </Stack>
  );
}

type SpeciesPageInnerProps = {
  handleClose: () => void;
  species: ServerData['species'];
};

function SpeciesPageInner(props: SpeciesPageInnerProps) {
  const { act, data } = useBackend<PreferencesMenuData>();
  const setSpecies = createSetPreference(act, 'species');

  const validSpecies = data.character_preferences.valid_choices?.species;
  const species: [string, Species][] = Object.entries(props.species).filter(
    ([species]) => !validSpecies || validSpecies.includes(species),
  );

  const humanIndex = species.findIndex(([species]) => species === 'Human');
  const swapWith = species[0];
  species[0] = species[humanIndex];
  species[humanIndex] = swapWith;

  const currentSpecies = props.species[data.character_preferences.misc.species];
  const { positive, negative, neutral } = currentSpecies.perks;
  const hasPerks = positive.length + negative.length + neutral.length > 0;

  return (
    <Stack vertical fill>
      <Stack.Item>
        <Button icon="arrow-left" onClick={props.handleClose}>
          Назад
        </Button>
      </Stack.Item>

      <Stack.Item grow>
        <Stack fill>
          <Stack.Item>
            <Box height="calc(100vh - 170px)" overflowY="auto" pr={3}>
              {species.map(([speciesKey, species]) => {
                return (
                  <Button
                    key={speciesKey}
                    onClick={() => setSpecies(speciesKey)}
                    selected={
                      data.character_preferences.misc.species === speciesKey
                    }
                    tooltip={species.name}
                    style={{
                      display: 'block',
                      height: '64px',
                      width: '64px',
                    }}
                  >
                    <Box
                      className={classes(['species64x64', species.icon])}
                      ml={-1}
                    />
                  </Button>
                );
              })}
            </Box>
          </Stack.Item>

          <Stack.Item grow>
            <Box>
              <Box>
                <Stack fill>
                  <Stack.Item width="70%">
                    <Section
                      title={currentSpecies.name}
                      buttons={
                        currentSpecies.diet && (
                          <Diet diet={currentSpecies.diet} />
                        )
                      }
                    >
                      <Section title="Описание">{currentSpecies.desc}</Section>

                      {hasPerks && (
                        <Section title="Особенности">
                          <SpeciesPerks perks={currentSpecies.perks} />
                        </Section>
                      )}
                    </Section>
                  </Stack.Item>

                  <Stack.Item width="30%">
                    <CharacterPreview
                      id={data.character_preview_view}
                      height="100%"
                    />
                  </Stack.Item>
                </Stack>
              </Box>

              {currentSpecies.lore.length > 0 && (
                <Box mt={1}>
                  <Section title="История">
                    <BlockQuote>
                      {currentSpecies.lore.map((text, index) => (
                        <Box key={index} maxWidth="100%">
                          {text}
                          {index !== currentSpecies.lore.length - 1 && (
                            <>
                              <br />
                              <br />
                            </>
                          )}
                        </Box>
                      ))}
                    </BlockQuote>
                  </Section>
                </Box>
              )}
            </Box>
          </Stack.Item>
        </Stack>
      </Stack.Item>
    </Stack>
  );
}

type SpeciesPageProps = {
  closeSpecies: () => void;
};

export function SpeciesPage(props: SpeciesPageProps) {
  const serverData = useServerPrefs();
  if (!serverData) {
    return <LoadingScreen />;
  }

  return (
    <SpeciesPageInner
      handleClose={props.closeSpecies}
      species={serverData.species}
    />
  );
}
