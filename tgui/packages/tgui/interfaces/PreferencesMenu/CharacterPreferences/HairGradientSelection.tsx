import { type MouseEvent, useEffect, useRef, useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Box, Button, LabeledList, Section, Stack } from 'tgui-core/components';
import { clamp } from 'tgui-core/math';
import { classes } from 'tgui-core/react';

import { features } from '../preferences/features';
import {
  type FeatureChoicedServerData,
  type FeatureNumericData,
  FeatureValueInput,
} from '../preferences/features/base';
import { createSetPreference, type PreferencesMenuData } from '../types';
import { useServerPrefs } from '../useServerPrefs';

const NO_GRADIENT = 'None';
const OPTION_SIZE = 48;
const PREVIEW_SIZE = 198;
const SELECTION_HEIGHT = 340;

type Offset = [number, number];

type HairGradientSelectionProps = {
  name: string;
  catalog: FeatureChoicedServerData;
  validChoices?: string[];
  selected: string;
  onSelect: (value: string) => void;
};

export function HairGradientSelection(props: HairGradientSelectionProps) {
  const { act, data } = useBackend<PreferencesMenuData>();
  const { catalog, selected, validChoices } = props;
  const supplemental = data.character_preferences.supplemental_features;
  const previews = data.hair_gradient_previews;

  const serverOffset: Offset = [
    supplemental.hair_gradient_offset_x as number,
    supplemental.hair_gradient_offset_y as number,
  ];
  const [offset, setOffset] = useState(serverOffset);
  const [dragging, setDragging] = useState(false);
  const imageRef = useRef<HTMLImageElement>(null);

  const offsetRange = useServerPrefs()?.hair_gradient_offset_x as
    | FeatureNumericData
    | undefined;
  const minOffset = offsetRange?.minimum ?? 0;
  const maxOffset = offsetRange?.maximum ?? 0;
  const disabled = selected === NO_GRADIENT;

  useEffect(() => {
    act('set_hair_gradient_preview', { open: true });
    return () => {
      act('set_hair_gradient_preview', { open: false });
    };
  }, []);

  useEffect(() => {
    if (!dragging) {
      setOffset(serverOffset);
    }
  }, [dragging, ...serverOffset]);

  function sendOffset(newOffset: Offset, oldOffset: Offset) {
    const clamped: Offset = [
      clamp(newOffset[0], minOffset, maxOffset),
      clamp(newOffset[1], minOffset, maxOffset),
    ];
    if (clamped[0] !== oldOffset[0]) {
      createSetPreference(act, 'hair_gradient_offset_x')(clamped[0]);
    }
    if (clamped[1] !== oldOffset[1]) {
      createSetPreference(act, 'hair_gradient_offset_y')(clamped[1]);
    }
    setOffset(clamped);
    return clamped;
  }

  function handleDragStart(event: MouseEvent) {
    const image = imageRef.current;
    if (disabled || !image?.naturalWidth) {
      return;
    }
    event.preventDefault();

    const scale = image.clientWidth / image.naturalWidth;
    const startX = event.clientX;
    const startY = event.clientY;
    const startOffset = offset;
    let lastOffset = offset;

    const handleMove = (moveEvent: globalThis.MouseEvent) => {
      lastOffset = sendOffset(
        [
          startOffset[0] + Math.round((moveEvent.clientX - startX) / scale),
          startOffset[1] - Math.round((moveEvent.clientY - startY) / scale),
        ],
        lastOffset,
      );
    };

    const handleUp = () => {
      window.removeEventListener('mousemove', handleMove);
      window.removeEventListener('mouseup', handleUp);
      setDragging(false);
    };

    window.addEventListener('mousemove', handleMove);
    window.addEventListener('mouseup', handleUp);
    setDragging(true);
  }

  const nudge = (x: number, y: number) => () =>
    sendOffset([offset[0] + x, offset[1] + y], offset);

  const choices = validChoices ?? Object.keys(catalog.icons ?? {});

  return (
    <Box
      className="ChoicedSelection"
      style={{ height: `${SELECTION_HEIGHT}px` }}
    >
      <Section fill title={`Выбор: ${props.name.toLowerCase()}`}>
        <Stack fill g={1}>
          <Stack.Item width={`${OPTION_SIZE * 3 + 24}px`}>
            <Section fill scrollable>
              <Stack wrap g={0.25}>
                {choices.map((choice) => (
                  <Stack.Item key={choice} m={0}>
                    <Button
                      onClick={() => props.onSelect(choice)}
                      selected={choice === selected}
                      tooltip={catalog.display_names?.[choice] ?? choice}
                      tooltipPosition="right"
                      p={0}
                      style={{
                        height: `${OPTION_SIZE}px`,
                        width: `${OPTION_SIZE}px`,
                      }}
                    >
                      {previews?.[choice] ? (
                        <img
                          className="PreferencesMenu__HairGradient__option"
                          src={`data:image/png;base64,${previews[choice]}`}
                        />
                      ) : (
                        <Box
                          className={classes([
                            'preferences32x32',
                            catalog.icons?.[choice],
                            'centered-image',
                          ])}
                        />
                      )}
                    </Button>
                  </Stack.Item>
                ))}
              </Stack>
            </Section>
          </Stack.Item>

          <Stack.Item width={`${PREVIEW_SIZE}px`}>
            <Stack vertical g={1}>
              <Stack.Item>
                <div
                  className={classes([
                    'PreferencesMenu__HairGradient__preview',
                    dragging &&
                      'PreferencesMenu__HairGradient__preview--dragging',
                    disabled &&
                      'PreferencesMenu__HairGradient__preview--disabled',
                  ])}
                  style={{
                    height: `${PREVIEW_SIZE}px`,
                    width: `${PREVIEW_SIZE}px`,
                  }}
                  title={
                    disabled ? undefined : 'Зажмите и тяните, чтобы сдвинуть'
                  }
                  onMouseDown={handleDragStart}
                >
                  {previews?.[selected] && (
                    <img
                      ref={imageRef}
                      src={`data:image/png;base64,${previews[selected]}`}
                    />
                  )}
                  {!disabled && (
                    <div className="PreferencesMenu__HairGradient__offset">
                      X {offset[0]} · Y {offset[1]}
                    </div>
                  )}
                </div>
              </Stack.Item>

              <Stack.Item>
                <LabeledList>
                  <LabeledList.Item label="Цвет">
                    <FeatureValueInput
                      feature={features.hair_gradient_colour}
                      featureId="hair_gradient_colour"
                      value={supplemental.hair_gradient_colour}
                    />
                  </LabeledList.Item>
                  <LabeledList.Item label="Сила">
                    <FeatureValueInput
                      feature={features.hair_gradient_alpha}
                      featureId="hair_gradient_alpha"
                      value={supplemental.hair_gradient_alpha}
                    />
                  </LabeledList.Item>
                  <LabeledList.Item label="Сдвиг">
                    <Stack g={0.25}>
                      <Button
                        icon="arrow-left"
                        disabled={disabled}
                        onClick={nudge(-1, 0)}
                      />
                      <Button
                        icon="arrow-up"
                        disabled={disabled}
                        onClick={nudge(0, 1)}
                      />
                      <Button
                        icon="arrow-down"
                        disabled={disabled}
                        onClick={nudge(0, -1)}
                      />
                      <Button
                        icon="arrow-right"
                        disabled={disabled}
                        onClick={nudge(1, 0)}
                      />
                      <Button
                        icon="rotate-left"
                        tooltip="Сбросить"
                        disabled={disabled || (!offset[0] && !offset[1])}
                        onClick={() => sendOffset([0, 0], offset)}
                      />
                    </Stack>
                  </LabeledList.Item>
                </LabeledList>
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Section>
    </Box>
  );
}
