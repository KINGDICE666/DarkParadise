import { Icon } from 'tgui-core/components';
import { classes } from 'tgui-core/react';

import { formatRadarDistance } from '../OvermapRadar';
import { Btn, useBridge } from './parts';

const CUSTOM_DOCK_ID = '__overmap_custom';

const Approach = () => {
  const { act, data } = useBridge();
  return (
    <div className="Bridge__stack Bridge__side Bridge__side--wide">
      <div className="Bridge__cta Bridge__cta--lit Bridge__grow">
        {data.dock_aligning ? 'СВОДИМ ШЛЮЗЫ…' : 'ЗАХОД'}
        <small>
          {data.dock_name} · {data.dock_distance ?? 0} м
        </small>
      </div>
      <Btn
        ghost
        disabled={!!data.dock_aligning}
        onClick={() => act('cancel_docking')}
      >
        ОТМЕНА ЗАХОДА
      </Btn>
    </div>
  );
};

export const DockDeck = () => {
  const {
    act,
    data,
    setSelection,
    flightLocked,
    dockPick: pick,
    setDockPick: setPick,
  } = useBridge();
  const world = data.radar_world;
  const span = data.cell_span || 100;
  const airlocks = (data.radar_docks || []).filter((dock) => !dock.own);
  const pads = (data.docks || []).filter((pad) => pad.id !== CUSTOM_DOCK_ID);
  const docked = data.phase === 'docked';
  const craft = data.docked_craft || [];
  const busy = !!data.gunner || !!data.programmed_locked;
  const pickedAirlock =
    pick?.kind === 'airlock' && airlocks.find((dock) => dock.id === pick.id);
  const pickedPad =
    pick?.kind === 'pad' && pads.find((pad) => pad.id === pick.id);
  const approach = () => {
    if (pickedAirlock) {
      act('select_radar_dock', { id: pickedAirlock.id });
    } else if (pickedPad) {
      act('prepare_landing', { id: pickedPad.id });
    }
  };
  let index = 0;
  return (
    <div className="Bridge__mode">
      <div className="Bridge__docks">
        {craft.map((guest) => (
          <div key={guest.id} className="Bridge__dockrow">
            <i>
              <Icon name="shuttle-space" />
            </i>
            <span>{guest.name}</span>
            <span
              className={classes([
                'Bridge__dockState',
                guest.busy && 'Bridge__dockState--busy',
              ])}
            >
              {guest.busy ? 'В РАБОТЕ' : 'У ПРИЧАЛА'}
            </span>
            <button
              type="button"
              className="Bridge__btn"
              disabled={busy || !!guest.busy}
              title="Отстыковать шаттл от корабля"
              onClick={() => act('release_craft', { id: guest.id })}
            >
              ВЫПУСТИТЬ
            </button>
          </div>
        ))}
        {airlocks.map((dock) => {
          index++;
          const free = !(dock.available === false || dock.available === 0);
          return (
            <button
              key={dock.id}
              type="button"
              disabled={!free}
              className={classes([
                'Bridge__dockrow',
                pick?.id === dock.id && 'Bridge__dockrow--sel',
              ])}
              onClick={() => {
                setPick({ kind: 'airlock', id: dock.id });
                setSelection({ kind: 'dock', id: dock.id });
              }}
            >
              <i>{String(index).padStart(2, '0')}</i>
              <span>{dock.name}</span>
              <span
                className={classes([
                  'Bridge__dockState',
                  !free && 'Bridge__dockState--busy',
                ])}
              >
                {free ? 'СВОБОДЕН' : 'ЗАНЯТ'}
              </span>
              <em>
                {world
                  ? formatRadarDistance(
                      Math.hypot(dock.x - world[0], dock.y - world[1]),
                      span,
                    ).replace('.', ',')
                  : '—'}
              </em>
            </button>
          );
        })}
        {pads.map((pad) => {
          index++;
          return (
            <button
              key={pad.id}
              type="button"
              disabled={!pad.can_dock}
              className={classes([
                'Bridge__dockrow',
                pick?.id === pad.id && 'Bridge__dockrow--sel',
              ])}
              onClick={() => setPick({ kind: 'pad', id: pad.id })}
            >
              <i>{String(index).padStart(2, '0')}</i>
              <span>{pad.name}</span>
              <span
                className={classes([
                  'Bridge__dockState',
                  !pad.can_dock && 'Bridge__dockState--busy',
                ])}
              >
                {pad.can_dock
                  ? 'ПЛОЩАДКА'
                  : (pad.reason || 'ЗАНЯТА').toUpperCase()}
              </span>
              <em>{data.host_name || ''}</em>
            </button>
          );
        })}
        {!airlocks.length && !pads.length && !craft.length && (
          <div className="Bridge__empty">
            {docked
              ? `Корабль пристыкован${data.ship_docked_to ? ` к ${data.ship_docked_to}` : ''}.`
              : 'Шлюзов и площадок в зоне нет. Подойдите ближе к станции или кораблю.'}
          </div>
        )}
        <div className="Bridge__keys Bridge__keys--foot">
          шлюзы подсвечены на радаре вблизи · клик по шлюзу — выбрать
        </div>
      </div>
      {data.dock_name ? (
        <Approach />
      ) : (
        <div className="Bridge__stack Bridge__side Bridge__side--wide">
          {docked ? (
            <button
              type="button"
              disabled={busy || !data.can_undock}
              className="Bridge__cta Bridge__grow"
              onClick={() => act('undock')}
            >
              ОТСТЫКОВАТЬСЯ
              <small>выход в открытый космос</small>
            </button>
          ) : (
            <button
              type="button"
              disabled={busy || flightLocked || (!pickedAirlock && !pickedPad)}
              className="Bridge__cta Bridge__grow"
              onClick={approach}
            >
              ЗАХОД
              <small>
                {pickedAirlock || pickedPad
                  ? `автодоводка: ${(pickedAirlock || pickedPad || { name: '' }).name}`
                  : 'выберите шлюз'}
              </small>
            </button>
          )}
          <Btn
            disabled={busy || !data.can_stop}
            onClick={() => act(data.is_pod ? 'dock' : 'prepare_stop')}
          >
            {data.is_pod ? 'СЕСТЬ ЗДЕСЬ' : 'ОСТАНОВКА В КОСМОСЕ'}
          </Btn>
          <Btn
            ghost
            disabled={busy || !data.can_ship_undock}
            onClick={() => act('dock_ship')}
          >
            {data.ship_docked_to ? 'ОТЦЕПИТЬСЯ' : 'ОТЦЕПИТЬ КОРАБЛИ'}
          </Btn>
        </div>
      )}
    </div>
  );
};
