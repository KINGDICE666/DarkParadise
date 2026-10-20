import { sortBy } from 'es-toolkit';
import { filter } from 'es-toolkit/compat';
import { useState } from 'react';
import {
  Box,
  Button,
  Divider,
  Icon,
  Input,
  NoticeBox,
  Section,
  Stack,
  Tabs,
  VirtualList,
} from 'tgui-core/components';
import { createSearch } from 'tgui-core/string';

import { useBackend } from '../../backend';
import { Window } from '../../layouts';
import { CAN_MAKE } from './constants';
import { MaterialContent } from './content/MaterialContent';
import { RecipeContent, RecipeContentCompact } from './content/RecipeContent';
import { getCategoryName, getFAIcon, toggleArrayItem } from './helpers';
import { type CraftingData, type Material, type Recipe, TABS } from './types';

export function PersonalCrafting() {
  const { act, data } = useBackend<CraftingData>();
  const { display_compact, display_craftable_only, craftability, atom_data } =
    data;

  const [searchText, setSearchText] = useState('');
  const [pages, setPages] = useState(1);

  const defaultCategory = Object.keys(craftability).length
    ? CAN_MAKE
    : data.categories[0];
  const [activeCategory, setCategory] = useState(defaultCategory);
  const [activeSubcategories, setSubcategories] = useState<string[]>();

  const material_occurences = sortBy(data.material_occurences, [
    (material) => -material.occurences,
  ]);
  const [activeMaterial, setMaterial] = useState(
    material_occurences[0]?.atom_id,
  );
  const [tabMode, setTabMode] = useState(TABS.category);

  const subcategories = data.recipes
    .reduce((acc: string[], recipe) => {
      if (
        recipe.category === activeCategory &&
        recipe.subcategory &&
        !acc.includes(recipe.subcategory)
      ) {
        acc.push(recipe.subcategory);
      }
      return acc;
    }, [])
    .sort((a, b) => (a > b ? 1 : -1));

  const searchName = createSearch(searchText, (item: Recipe) => item.name);

  const searchMaterial = createSearch(
    searchText,
    (material: Material) =>
      atom_data[Number(material.atom_id) - 1]?.name || material.atom_id,
  );

  const filteredMaterials =
    searchText.length > 0 && tabMode === TABS.material
      ? filter(material_occurences, searchMaterial)
      : material_occurences;

  function categoryMatch(recipe: Recipe): boolean {
    if (tabMode === TABS.material) {
      return Object.keys(recipe.reqs).includes(activeMaterial);
    }
    if (activeCategory === CAN_MAKE) {
      return Boolean(craftability[recipe.ref]);
    }
    if (
      activeSubcategories?.length &&
      !activeSubcategories.includes(recipe.subcategory)
    ) {
      return false;
    }
    return recipe.category === activeCategory;
  }

  let recipes = filter(
    data.recipes,
    (recipe) =>
      (!display_craftable_only || Boolean(craftability[recipe.ref])) &&
      (searchText.length > 0 || categoryMatch(recipe)),
  );
  recipes = sortBy(recipes, [
    (recipe) => [
      activeCategory === CAN_MAKE
        ? 99 - Object.keys(recipe.reqs).length
        : Number(craftability[recipe.ref]),
      recipe.name.toLowerCase(),
    ],
  ]);
  if (searchText.length > 0) {
    recipes = filter(recipes, searchName);
  }

  const categories = [CAN_MAKE].concat(
    [...data.categories].sort((a, b) =>
      getCategoryName(a).localeCompare(getCategoryName(b)),
    ),
  );

  const pageSize =
    searchText.length > 0
      ? display_compact
        ? 20
        : 10
      : display_compact
        ? 60
        : 30;
  const displayLimit = pageSize * pages;
  const content = document.getElementById('content');

  return (
    <Window width={700} height={720}>
      <Window.Content>
        <Stack fill>
          <Stack.Item width="200px">
            <Section fill>
              <Stack fill vertical justify="space-between">
                <Stack.Item>
                  <Input
                    autoFocus
                    expensive
                    placeholder={`Поиск среди ${data.recipes.length} рецептов...`}
                    value={searchText}
                    onChange={(value) => {
                      setPages(1);
                      setSearchText(value);
                    }}
                    fluid
                  />
                </Stack.Item>
                <Stack.Item>
                  <Tabs fluid textAlign="center">
                    <Tabs.Tab
                      selected={tabMode === TABS.category}
                      onClick={() => {
                        if (tabMode === TABS.category) {
                          return;
                        }
                        setTabMode(TABS.category);
                        setPages(1);
                        setCategory(defaultCategory);
                        setSubcategories(undefined);
                      }}
                    >
                      Категории
                    </Tabs.Tab>
                    <Tabs.Tab
                      selected={tabMode === TABS.material}
                      onClick={() => {
                        if (tabMode === TABS.material) {
                          return;
                        }
                        setTabMode(TABS.material);
                        setPages(1);
                        setMaterial(material_occurences[0]?.atom_id);
                      }}
                    >
                      Материалы
                    </Tabs.Tab>
                  </Tabs>
                </Stack.Item>
                <Stack.Item grow m={-1} style={{ overflowY: 'auto' }}>
                  <Box height="100%" p={1}>
                    <Tabs vertical>
                      {tabMode === TABS.material &&
                        filteredMaterials.map((material) => (
                          <Tabs.Tab
                            key={material.atom_id}
                            selected={
                              activeMaterial === material.atom_id &&
                              searchText.length === 0
                            }
                            onClick={() => {
                              setMaterial(material.atom_id);
                              setPages(1);
                              if (content) {
                                content.scrollTop = 0;
                              }
                              if (searchText.length > 0) {
                                setSearchText('');
                              }
                            }}
                          >
                            <MaterialContent
                              atom_id={material.atom_id}
                              occurences={material.occurences}
                            />
                          </Tabs.Tab>
                        ))}
                      {tabMode === TABS.category &&
                        categories.map((category) => (
                          <Tabs.Tab
                            key={category}
                            selected={
                              activeCategory === category &&
                              searchText.length === 0
                            }
                            onClick={() => {
                              if (category !== activeCategory) {
                                setSubcategories(undefined);
                              }
                              setCategory(category);
                              setPages(1);
                              if (content) {
                                content.scrollTop = 0;
                              }
                              if (searchText.length > 0) {
                                setSearchText('');
                              }
                            }}
                          >
                            <Stack vertical>
                              <Stack.Item>
                                <Stack>
                                  <Stack.Item width="14px" textAlign="center">
                                    <Icon name={getFAIcon(category)} />
                                  </Stack.Item>
                                  <Stack.Item grow>
                                    {getCategoryName(category)}
                                  </Stack.Item>
                                  {category === CAN_MAKE && (
                                    <Stack.Item>
                                      {Object.keys(craftability).length}
                                    </Stack.Item>
                                  )}
                                </Stack>
                              </Stack.Item>
                              {category === activeCategory &&
                                subcategories.length > 1 && (
                                  <Stack.Item fontSize="0.95em">
                                    <Stack vertical pb={1}>
                                      {subcategories.map((subcategory) => (
                                        <Stack.Item key={subcategory}>
                                          <Button.Checkbox
                                            fluid
                                            checked={activeSubcategories?.includes(
                                              subcategory,
                                            )}
                                            onClick={() => {
                                              setSubcategories(
                                                toggleArrayItem(
                                                  activeSubcategories,
                                                  subcategory,
                                                ),
                                              );
                                              setPages(1);
                                            }}
                                          >
                                            {getCategoryName(subcategory)}
                                          </Button.Checkbox>
                                        </Stack.Item>
                                      ))}
                                    </Stack>
                                  </Stack.Item>
                                )}
                            </Stack>
                          </Tabs.Tab>
                        ))}
                    </Tabs>
                  </Box>
                </Stack.Item>
                <Stack.Item>
                  <Divider />
                  <Button.Checkbox
                    fluid
                    checked={display_craftable_only}
                    onClick={() => act('toggle_recipes')}
                  >
                    Только доступные
                  </Button.Checkbox>
                  <Button.Checkbox
                    fluid
                    checked={display_compact}
                    onClick={() => act('toggle_compact')}
                  >
                    Компактный список
                  </Button.Checkbox>
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>
          <Stack.Item grow my={-1}>
            <Box
              height="100%"
              pr={1}
              pt={1}
              mr={-1}
              style={{ overflowY: 'auto' }}
            >
              {recipes.length > 0 ? (
                <VirtualList>
                  {recipes
                    .slice(0, displayLimit)
                    .map((item) =>
                      display_compact ? (
                        <RecipeContentCompact key={item.ref} item={item} />
                      ) : (
                        <RecipeContent key={item.ref} item={item} />
                      ),
                    )}
                </VirtualList>
              ) : (
                <NoticeBox m={1} p={1}>
                  Рецепты не найдены.
                </NoticeBox>
              )}
              {recipes.length > displayLimit && (
                <Section
                  mb={1}
                  textAlign="center"
                  style={{ cursor: 'pointer' }}
                  onClick={() => setPages(pages + 1)}
                >
                  Показать ещё{' '}
                  {Math.min(pageSize, recipes.length - displayLimit)}...
                </Section>
              )}
            </Box>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
}
