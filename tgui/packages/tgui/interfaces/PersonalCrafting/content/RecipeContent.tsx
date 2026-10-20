import {
  Box,
  Button,
  Icon,
  Section,
  Stack,
  Tooltip,
} from 'tgui-core/components';

import { useBackend } from '../../../backend';
import { GroupTitle } from '../GroupTitle';
import { findIcon, formatAmount, getToolName } from '../helpers';
import type { CraftingData, Recipe } from '../types';
import { AtomContent } from './AtomContent';
import { ToolContent } from './ToolContent';

type Props = {
  item: Recipe;
};

function atomListText(
  atoms: Record<number, number> | undefined,
  data: CraftingData,
): string[] {
  if (!atoms) {
    return [];
  }
  return Object.keys(atoms).map((id) => {
    const atom = data.atom_data[Number(id) - 1];
    return `${atom?.name}${formatAmount(atoms[id], atom?.is_reagent)}`;
  });
}

export function RecipeContentCompact(props: Props) {
  const { item } = props;
  const { data } = useBackend<CraftingData>();

  const requirements = [
    ...atomListText(item.reqs, data),
    ...atomListText(item.chem_catalysts, data),
    ...(item.tool_paths || []).map(
      (tool) => data.atom_data[Number(tool) - 1]?.name,
    ),
  ];

  return (
    <Section>
      <Stack my={-0.75}>
        <Stack.Item>
          <Box className={findIcon(item.id, data)} />
        </Stack.Item>
        <Stack.Item grow>
          <Stack>
            <Stack.Item grow>
              <Box mb={0.5} bold style={{ textTransform: 'capitalize' }}>
                {item.name}
              </Box>
              <Box style={{ textTransform: 'capitalize' }} color="gray">
                {requirements.join(', ')}
              </Box>
            </Stack.Item>
            <Stack.Item>
              <Box>
                {!!item.tool_behaviors && (
                  <Tooltip
                    content={`Инструменты: ${item.tool_behaviors.map(getToolName).join(', ')}`}
                  >
                    <Icon p={1} name="screwdriver-wrench" />
                  </Tooltip>
                )}
                <CraftButton item={item} />
              </Box>
            </Stack.Item>
          </Stack>
        </Stack.Item>
      </Stack>
    </Section>
  );
}

type FullProps = Props & {
  nodesc?: boolean;
  setParentForceFloating?: (state: boolean) => void;
  showIcon?: boolean;
};

export function RecipeContent(props: FullProps) {
  const {
    item,
    nodesc = false,
    setParentForceFloating,
    showIcon = true,
  } = props;
  const { data } = useBackend<CraftingData>();
  const { chem_catalysts } = item;

  return (
    <Section>
      <Stack>
        {showIcon && (
          <Stack.Item>
            <Box textAlign="center" minWidth="64px" minHeight="64px" mr={1}>
              <Box
                style={{
                  transform: 'scale(1.5)',
                }}
                m="16px"
                className={findIcon(item.id, data)}
              />
            </Box>
          </Stack.Item>
        )}
        <Stack.Item grow>
          <Stack>
            <Stack.Item grow={5}>
              <Box mb={1} bold style={{ textTransform: 'capitalize' }}>
                {nodesc ? (
                  <CraftButton item={item} buttonText={item.name} />
                ) : (
                  item.name
                )}
              </Box>
              {!nodesc && item.desc && <Box color="gray">{item.desc}</Box>}
              <Box style={{ textTransform: 'capitalize' }}>
                {Object.keys(item.reqs).length > 0 && (
                  <Box>
                    <GroupTitle title="Материалы" />
                    {Object.keys(item.reqs).map((atom_id) => (
                      <AtomContent
                        key={atom_id}
                        atom_id={atom_id}
                        amount={item.reqs[atom_id]}
                        setParentForceFloating={setParentForceFloating}
                      />
                    ))}
                  </Box>
                )}
                {chem_catalysts && (
                  <Box>
                    <GroupTitle title="Катализаторы" />
                    {Object.keys(chem_catalysts).map((atom_id) => (
                      <AtomContent
                        key={atom_id}
                        atom_id={atom_id}
                        amount={chem_catalysts[atom_id]}
                        setParentForceFloating={setParentForceFloating}
                      />
                    ))}
                  </Box>
                )}
                {(item.tool_paths || item.tool_behaviors) && (
                  <Box>
                    <GroupTitle title="Инструменты" />
                    {item.tool_paths?.map((tool) => (
                      <AtomContent
                        key={tool}
                        atom_id={tool}
                        amount={1}
                        setParentForceFloating={setParentForceFloating}
                      />
                    ))}
                    {item.tool_behaviors?.map((tool) => (
                      <ToolContent key={tool} tool={tool} />
                    ))}
                  </Box>
                )}
              </Box>
            </Stack.Item>
            {!nodesc && (
              <Stack.Item pl={1} grow={2}>
                <CraftButton item={item} />
              </Stack.Item>
            )}
          </Stack>
        </Stack.Item>
      </Stack>
    </Section>
  );
}

type CraftProps = {
  item: Recipe;
  buttonText?: string;
};

function CraftButton(props: CraftProps) {
  const { act, data } = useBackend<CraftingData>();
  const { item, buttonText } = props;
  const { busy, craftability } = data;
  const craftable = Boolean(craftability[item.ref]);

  return (
    <Button
      lineHeight={2.5}
      align="center"
      fluid
      disabled={!craftable || busy}
      icon={busy ? 'circle-notch' : 'hammer'}
      iconSpin={!!busy}
      onClick={() =>
        act('make', {
          recipe: item.ref,
        })
      }
    >
      {buttonText ?? 'Сделать'}
    </Button>
  );
}
