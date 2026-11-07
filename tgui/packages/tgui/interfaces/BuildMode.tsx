import { useEffect, useMemo, useState } from 'react';
import {
  Box,
  Button,
  ImageButton,
  Input,
  NoticeBox,
  Section,
  Stack,
  Tabs,
} from 'tgui-core/components';
import { useFuzzySearch } from 'tgui-core/fuzzysearch';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type BuildModeItem = {
  path: string;
  name: string;
};

type BuildModeData = {
  categories: { name: string; items: BuildModeItem[] }[];
  selected_item: string | null;
  pixel_positioning: boolean;
  build_dir: number;
  preview_icons: Record<string, string>;
};

const PAGE_SIZE = 96;
const DIRECTIONS = [
  { direction: 8, label: 'З', title: 'Запад' },
  { direction: 9, label: 'СЗ', title: 'Северо-запад' },
  { direction: 1, label: 'С', title: 'Север' },
  { direction: 5, label: 'СВ', title: 'Северо-восток' },
  { direction: 4, label: 'В', title: 'Восток' },
  { direction: 6, label: 'ЮВ', title: 'Юго-восток' },
  { direction: 2, label: 'Ю', title: 'Юг' },
  { direction: 10, label: 'ЮЗ', title: 'Юго-запад' },
];

export function BuildMode() {
  const { act, data } = useBackend<BuildModeData>();
  const {
    categories,
    selected_item,
    pixel_positioning,
    build_dir,
    preview_icons = {},
  } = data;
  const [categoryIndex, setCategoryIndex] = useState(0);
  const [page, setPage] = useState(0);
  const currentItems = categories[categoryIndex]?.items || [];
  const selectedItem = useMemo(
    () =>
      categories
        .flatMap((category) => category.items)
        .find((item) => item.path === selected_item),
    [categories, selected_item],
  );
  const { query, setQuery, results } = useFuzzySearch({
    searchArray: currentItems,
    matchStrategy: 'smart',
    getSearchString: (item: BuildModeItem) => `${item.path} ${item.name}`,
  });
  const displayItems = query ? results : currentItems;
  const pageCount = Math.max(1, Math.ceil(displayItems.length / PAGE_SIZE));
  const currentPage = Math.min(page, pageCount - 1);
  const visibleItems = displayItems.slice(
    currentPage * PAGE_SIZE,
    (currentPage + 1) * PAGE_SIZE,
  );
  const previewPaths = visibleItems.map((item) => item.path).join(',');
  useEffect(() => {
    const timer = setTimeout(() => {
      act('request_previews', {
        paths: previewPaths ? previewPaths.split(',') : [],
      });
    }, 100);
    return () => clearTimeout(timer);
  }, [act, previewPaths, selected_item]);
  const pixelAvailable = selected_item && !selected_item.startsWith('/turf');

  return (
    <Window height={650} title="Панель строительства" width={850}>
      <Window.Content>
        <Stack fill>
          <Stack.Item basis="130px">
            <Tabs vertical>
              {categories.map((category, index) => (
                <Tabs.Tab
                  key={category.name}
                  selected={categoryIndex === index}
                  onClick={() => {
                    setCategoryIndex(index);
                    setPage(0);
                  }}
                >
                  {category.name}
                </Tabs.Tab>
              ))}
            </Tabs>
          </Stack.Item>
          <Stack.Item grow>
            <Stack vertical fill>
              <Stack.Item>
                <Section>
                  <Stack align="center">
                    <Stack.Item grow>
                      <Input
                        fluid
                        placeholder="Поиск по имени или пути типа..."
                        value={query}
                        onChange={(value) => {
                          setQuery(value);
                          setPage(0);
                        }}
                      />
                    </Stack.Item>
                    <Stack.Item>
                      <Button
                        icon="crosshairs"
                        selected={pixel_positioning}
                        disabled={!pixelAvailable}
                        tooltip="Размещать объекты со смещением под курсором"
                        onClick={() => act('toggle_pixel')}
                      >
                        Пиксели
                      </Button>
                    </Stack.Item>
                    <Stack.Item>
                      <Button
                        icon="times"
                        disabled={!selected_item}
                        onClick={() => act('clear_selection')}
                      >
                        Сбросить
                      </Button>
                    </Stack.Item>
                  </Stack>
                  <Box mt={1}>
                    Направление:{' '}
                    {DIRECTIONS.map(({ direction, label, title }) => (
                      <Button
                        key={direction}
                        selected={build_dir === direction}
                        tooltip={title}
                        onClick={() =>
                          act('set_direction', {
                            direction,
                          })
                        }
                      >
                        {label}
                      </Button>
                    ))}
                  </Box>
                </Section>
              </Stack.Item>
              <Stack.Item>
                <Section>
                  {selected_item ? (
                    <Stack align="center">
                      {preview_icons[selected_item] && (
                        <Stack.Item>
                          <ImageButton
                            base64={preview_icons[selected_item]}
                            imageSize={32}
                            selected
                          />
                        </Stack.Item>
                      )}
                      <Stack.Item grow>
                        <Box bold>
                          {selectedItem?.name || 'Выбрано с карты'}
                        </Box>
                        <Box color="label" fontSize="11px">
                          {selected_item}
                        </Box>
                      </Stack.Item>
                    </Stack>
                  ) : (
                    <Box color="label">Выберите тип для строительства.</Box>
                  )}
                </Section>
              </Stack.Item>
              <Stack.Item grow>
                <Section fill scrollable>
                  {displayItems.length === 0 ? (
                    <NoticeBox>Ничего не найдено.</NoticeBox>
                  ) : (
                    <Stack wrap>
                      {visibleItems.map((item) => (
                        <Stack.Item key={item.path} mb={1}>
                          <Box width="72px" textAlign="center">
                            <ImageButton
                              base64={preview_icons[item.path]}
                              imageSize={32}
                              selected={selected_item === item.path}
                              tooltip={`${item.name} (${item.path})`}
                              onClick={() =>
                                act('select_item', {
                                  path: item.path,
                                })
                              }
                            />
                            <Box
                              fontSize="10px"
                              style={{
                                overflow: 'hidden',
                                textOverflow: 'ellipsis',
                                whiteSpace: 'nowrap',
                              }}
                            >
                              {item.name}
                            </Box>
                          </Box>
                        </Stack.Item>
                      ))}
                    </Stack>
                  )}
                </Section>
              </Stack.Item>
              <Stack.Item>
                <Stack align="center" justify="space-between">
                  <Stack.Item>
                    <Button
                      icon="chevron-left"
                      disabled={currentPage === 0}
                      onClick={() => setPage(currentPage - 1)}
                    >
                      Назад
                    </Button>
                    {currentPage + 1} / {pageCount}
                    <Button
                      ml={1}
                      icon="chevron-right"
                      disabled={currentPage + 1 >= pageCount}
                      onClick={() => setPage(currentPage + 1)}
                    >
                      Далее
                    </Button>
                  </Stack.Item>
                  <Stack.Item color="label">
                    Найдено: {displayItems.length}
                  </Stack.Item>
                </Stack>
              </Stack.Item>
              <Stack.Item fontSize="11px" color="label">
                ЛКМ — поставить · Alt+ЛКМ — взять тип · ПКМ — сбросить · Alt+ПКМ
                — удалить объект
                {pixel_positioning && (
                  <Box>Alt+клик в пиксельном режиме открывает выбор цели.</Box>
                )}
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
}
