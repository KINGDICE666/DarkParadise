import { useState } from 'react';
import { Box, Button, Floating, Stack } from 'tgui-core/components';

import { useBackend } from '../../../backend';
import { findIcon, formatAmount } from '../helpers';
import type { AtomData, CraftingData } from '../types';
import { RecipeContent } from './RecipeContent';

type Props = {
  amount: number;
  atom_id: string;
  setParentForceFloating?: (state: boolean) => void;
};

export function AtomContent(props: Props) {
  const { amount, atom_id, setParentForceFloating } = props;
  const { data } = useBackend<CraftingData>();
  const { atom_data, recipes } = data;

  const atom_id_int = Number(atom_id);
  const atom = atom_data[atom_id_int - 1];

  const hasRecipe = recipes.filter((recipe) => recipe.id === atom_id_int);
  const [forceFloating, setForceFloating] = useState(false);
  const [shownRecipe, setShownRecipe] = useState(hasRecipe[0]);

  if (hasRecipe.length <= 0) {
    return (
      <AtomContentInner
        atom={atom}
        atom_id={atom_id_int}
        amount={amount}
        underline={false}
      />
    );
  }

  return (
    <Floating
      handleOpen={forceFloating || undefined}
      disabled={forceFloating}
      placement="bottom"
      closeAfterInteract={false}
      hoverOpen
      hoverSafePolygon
      onOpenChange={(state) => {
        if (setParentForceFloating) {
          setParentForceFloating(state);
        }
        if (!state) {
          setForceFloating(false);
        }
      }}
      content={
        <Box
          p={0.5}
          backgroundColor="hsl(0, 0%, 15%)"
          style={{
            borderRadius: '4px',
            backdropFilter: 'blur(12px)',
          }}
        >
          {hasRecipe.length > 1 && (
            <Stack align="center" fill mb={0.5}>
              <Stack.Item grow>
                <Button
                  fluid
                  icon="arrow-left"
                  align="center"
                  onClick={() =>
                    setShownRecipe(
                      hasRecipe[
                        (hasRecipe.indexOf(shownRecipe) -
                          1 +
                          hasRecipe.length) %
                          hasRecipe.length
                      ],
                    )
                  }
                />
              </Stack.Item>
              <Stack.Item grow>
                <Button
                  fluid
                  icon="arrow-right"
                  align="center"
                  onClick={() =>
                    setShownRecipe(
                      hasRecipe[
                        (hasRecipe.indexOf(shownRecipe) + 1) % hasRecipe.length
                      ],
                    )
                  }
                />
              </Stack.Item>
            </Stack>
          )}
          <RecipeContent
            item={shownRecipe}
            nodesc
            setParentForceFloating={setForceFloating}
            showIcon={false}
          />
        </Box>
      }
    >
      <Box>
        <AtomContentInner
          atom={atom}
          atom_id={atom_id_int}
          amount={amount}
          underline
        />
      </Box>
    </Floating>
  );
}

type AtomContentInnerProps = {
  atom: AtomData;
  atom_id: number;
  amount: number;
  underline?: boolean;
};

function AtomContentInner(props: AtomContentInnerProps) {
  const { atom, atom_id, amount, underline = false } = props;
  const { data } = useBackend<CraftingData>();

  return (
    <Box my={1}>
      <Box
        verticalAlign="middle"
        inline
        my={-1}
        mr={0.5}
        className={findIcon(atom_id, data)}
      />
      <Box inline verticalAlign="middle">
        {underline ? (
          <Box
            inline
            style={{
              borderBottom: '2px dotted rgba(255, 255, 255, 0.8)',
            }}
          >
            {atom.name}
          </Box>
        ) : (
          atom.name
        )}
        {formatAmount(amount, atom.is_reagent)}
      </Box>
    </Box>
  );
}
