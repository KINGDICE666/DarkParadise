import { Fragment } from 'react';
import { Box, Button, Section, Stack } from 'tgui-core/components';
import { useBackend } from '../../backend';
import { EFFECTS_ALL, POD_GREY } from './constants';
import { useCompact } from './hooks';
import type { PodEffect, PodLauncherData } from './types';

export const PodStatusPage = (props: unknown) => {
  const [compact] = useCompact();

  return (
    <Section fill>
      <Stack>
        {EFFECTS_ALL.map((effectType, typeIdx) => (
          <Fragment key={typeIdx}>
            <Stack.Item>
              <Box bold color="label" mb={1}>
                {!compact && (effectType.alt_label || effectType.label)}:
              </Box>
              <Box>
                {effectType.list.map((effect, effectIdx) => (
                  <EffectDisplay
                    effect={effect}
                    hasMargin={effectType.list.length > 1}
                    index={effectIdx}
                    key={effectIdx}
                  />
                ))}
              </Box>
            </Stack.Item>
            {typeIdx < EFFECTS_ALL.length && <Stack.Divider />}
            {typeIdx === EFFECTS_ALL.length - 1 && <Extras />}
          </Fragment>
        ))}
      </Stack>
    </Section>
  );
};

const getEffectTooltip = (
  effect: Extract<PodEffect, { act: string }>,
  data: PodLauncherData,
) => {
  const lines = effect.title.split('\n');
  if (effect.act === 'effectShrapnel' && data.effectShrapnel) {
    lines.push(data.shrapnelType, `Размер: ${data.shrapnelMagnitude}`);
  } else if (effect.act === 'effectGas' && data.effectGas) {
    for (const [gasId, gas] of Object.entries(data.gasRelease)) {
      lines.push(
        `${data.gasNames[gasId] || gasId}: ${gas.amount} моль, ${gas.rate} моль/с`,
      );
    }
  }
  return lines.map((line) => <div key={line}>{line}</div>);
};

const EffectDisplay = (props) => {
  const { effect, hasMargin, index } = props;
  const { act, data } = useBackend<PodLauncherData>();
  const { payload } = data;

  if (effect.divider || !('icon' in effect)) {
    return (
      <span style={POD_GREY}>
        <b>|</b>
      </span>
    );
  }

  return (
    <Button
      icon={effect.icon}
      onClick={() =>
        payload ? act(effect.act, effect.payload) : act(effect.act)
      }
      selected={
        effect.soloSelected
          ? data[effect.soloSelected]
          : data[effect.selected as string] === effect.choiceNumber
      }
      style={{
        borderRadius: '5px',
        marginLeft: index !== 0 ? '1px' : '0px',
        marginRight: hasMargin ? '1px' : '0px',
        verticalAlign: 'middle',
      }}
      tooltip={getEffectTooltip(effect, data)}
      tooltipPosition={effect.tooltipPosition}
    >
      {effect.content}
    </Button>
  );
};

const Extras = (props: unknown) => {
  const { act } = useBackend();
  const [compact, setCompact] = useCompact();

  return (
    <Stack.Item>
      <Box color="label" mb={1}>
        <b>Экстра:</b>
      </Box>
      <Box>
        <Button
          color="transparent"
          icon="list-alt"
          inline
          m={0}
          onClick={() => act('gamePanel')}
          tooltip="Гейм панель"
          tooltipPosition="top-start"
        />
        <Button
          color="transparent"
          icon="hammer"
          inline
          m={0}
          onClick={() => act('buildMode')}
          tooltip="Билд мод"
          tooltipPosition="top-start"
        />
        <Button
          color="transparent"
          icon={compact ? 'expand' : 'compress'}
          inline
          m={0}
          onClick={() => setCompact(!compact)}
          tooltip={compact ? 'Расширенный режим' : 'Компактный режим'}
          tooltipPosition="top-start"
        />
      </Box>
    </Stack.Item>
  );
};
