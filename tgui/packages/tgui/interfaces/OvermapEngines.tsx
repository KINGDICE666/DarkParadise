import {
  Button,
  NoticeBox,
  NumberInput,
  ProgressBar,
  Section,
} from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import {
  OvermapFrame,
  OvermapList,
  OvermapRail,
  OvermapRow,
  OvermapStat,
  OvermapStats,
} from './overmap/OvermapChrome';

type EngineInfo = {
  name: string;
  ref: string;
  on: BooleanLike;
  thrust: number;
  limit: number;
  status: string;
  heat: number;
  overheated: BooleanLike;
  overdrive: BooleanLike;
};

type OvermapEnginesData = {
  linked: BooleanLike;
  vessel_name: string;
  global_on: BooleanLike;
  global_limit: number;
  total_thrust: number;
  mass: number;
  accel: number;
  overdrive: BooleanLike;
  engines: EngineInfo[];
};

export const OvermapEngines = () => {
  const { act, data } = useBackend<OvermapEnginesData>();
  const {
    linked,
    vessel_name,
    global_on,
    global_limit,
    total_thrust,
    mass = 0,
    accel = 0,
    overdrive,
    engines = [],
  } = data;

  return (
    <OvermapFrame
      title="Engines"
      width={560}
      height={480}
      linked={linked}
      onRelink={() => act('relink')}
      rail={
        <OvermapRail
          name={vessel_name || 'Engines'}
          lamps={[
            { label: 'банк', on: !!global_on },
            { label: 'форсаж', on: !!overdrive },
            { label: `${engines.length} уст.`, on: !!engines.length },
          ]}
        />
      }
      actions={
        linked ? (
          <>
            <Button
              icon="fire"
              color={overdrive ? 'orange' : undefined}
              selected={!!overdrive}
              tooltip="Тяга x1.5, двигатели греются и могут аварийно заглохнуть"
              onClick={() => act('toggle_overdrive')}
            >
              Форсаж
            </Button>
            <Button
              icon="power-off"
              selected={!!global_on}
              onClick={() => act('global_toggle')}
            >
              {global_on ? 'Все вкл' : 'Все выкл'}
            </Button>
          </>
        ) : null
      }
    >
      <div className="OvermapPanel">
        <OvermapStats>
          <OvermapStat label="тяга" value={total_thrust} />
          <OvermapStat label="масса" value={`${mass} т`} />
          <OvermapStat label="тяга/масса" value={accel} />
          <OvermapStat label="лимит" value={`${global_limit}%`} />
        </OvermapStats>
        <div style={{ margin: '0.5em 0' }}>
          Глобальный лимит
          <NumberInput
            ml={1}
            width="70px"
            unit="%"
            value={global_limit}
            minValue={0}
            maxValue={100}
            step={5}
            onChange={(value) => act('set_global_limit', { value: value })}
          />
        </div>
        <Section fill scrollable title="Установки">
          <OvermapList>
            {engines.map((engine) => (
              <OvermapRow
                key={engine.ref}
                selected={!!engine.on}
                title={engine.name}
                meta={`${engine.status} · тяга ${engine.thrust}`}
              >
                <ProgressBar
                  width="70px"
                  value={engine.heat}
                  minValue={0}
                  maxValue={100}
                  ranges={{
                    good: [-Infinity, 50],
                    average: [50, 85],
                    bad: [85, Infinity],
                  }}
                >
                  {engine.overheated ? 'ПЕРЕГРЕВ' : `${engine.heat}°`}
                </ProgressBar>
                <NumberInput
                  width="56px"
                  unit="%"
                  value={engine.limit}
                  minValue={0}
                  maxValue={100}
                  step={5}
                  onChange={(value) =>
                    act('set_engine_limit', {
                      ref: engine.ref,
                      value: value,
                    })
                  }
                />
                <Button
                  selected={!!engine.on}
                  onClick={() => act('toggle_engine', { ref: engine.ref })}
                >
                  {engine.on ? 'Вкл' : 'Выкл'}
                </Button>
              </OvermapRow>
            ))}
          </OvermapList>
          {!engines.length && <NoticeBox>Двигатели не найдены.</NoticeBox>}
        </Section>
      </div>
    </OvermapFrame>
  );
};
