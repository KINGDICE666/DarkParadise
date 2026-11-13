import { useEffect, useRef } from 'react';
import { globalEvents } from 'tgui-core/events';
import {
  acquireHotKey,
  listenForKeyEvents,
  releaseHotKey,
} from 'tgui-core/hotkeys';
import {
  KEY_1,
  KEY_2,
  KEY_3,
  KEY_B,
  KEY_C,
  KEY_ESCAPE,
  KEY_F,
  KEY_G,
  KEY_H,
  KEY_P,
  KEY_R,
  KEY_SHIFT,
  KEY_SPACE,
  KEY_T,
  KEY_V,
  KEY_Z,
} from 'tgui-core/keycodes';
import { classes } from 'tgui-core/react';

import { OvermapFrame } from '../OvermapChrome';
import {
  type HazardField,
  OvermapRadar,
  type RadarContact,
  type RadarProjectile,
} from '../OvermapRadar';
import { throttleIndex } from './bridgeMath';
import { DockDeck } from './DockDeck';
import { HeadingDeck, toggleHold } from './HeadingDeck';
import {
  ContactsCorner,
  MotionCorner,
  SelectedCorner,
  ViewCorner,
} from './HudCorners';
import { NavDeck } from './NavDeck';
import { BridgeProvider, Btn, Deck, useBridge } from './parts';
import { SystemsDeck } from './SystemsDeck';
import {
  actionAvailable,
  POST_ACTIONS,
  resolveSelection,
  runAction,
  visibleObjects,
} from './selection';
import { salvoParams, TacDeck } from './TacDeck';
import { setThrottle, ThrottleDeck } from './ThrottleDeck';
import { TopStrip } from './TopStrip';
import type { Post, Selection, Weapon } from './types';

const DOUBLE_CLICK = 400;
const POINT_SLOP = 0.02;
const BRIDGE_KEYS = [
  KEY_1,
  KEY_2,
  KEY_3,
  KEY_R,
  KEY_F,
  KEY_V,
  KEY_B,
  KEY_C,
  KEY_Z,
  KEY_P,
  KEY_T,
  KEY_G,
  KEY_H,
];
const POST_KEYS: Record<number, Post> = {
  [KEY_1]: 'nav',
  [KEY_2]: 'tac',
  [KEY_3]: 'dock',
};
const MIDDLE_TITLES: Record<Post, string> = {
  nav: 'МАРШРУТ',
  tac: 'УПРАВЛЕНИЕ ОГНЁМ',
  dock: 'СТЫКОВКА',
};
const TARGET_KINDS = ['unknown', 'shuttle', 'pod'];
const NO_CONTACTS: RadarContact[] = [];
const NO_DRIFTERS: number[][] = [];
const NO_PROJECTILES: RadarProjectile[] = [];
const NO_FIELDS: HazardField[] = [];
const NO_ARCS: Weapon[] = [];

const useBridgeKeys = (onKey: (code: number) => void) => {
  const handler = useRef(onKey);
  handler.current = onKey;
  useEffect(() => {
    const held: Record<string, boolean> = {};
    const relay = (name: string, down: boolean) => {
      if (!!held[name] === down) {
        return;
      }
      held[name] = down;
      Byond.command(`${down ? 'KeyDown' : 'KeyUp'} "${name}" 0 0 0 0`);
    };
    const releaseAll = () => {
      relay('Space', false);
      relay('Shift', false);
    };
    for (const code of BRIDGE_KEYS) {
      acquireHotKey(code);
    }
    const stop = listenForKeyEvents((key) => {
      if (key.code === KEY_SPACE) {
        relay('Space', key.isDown());
        return;
      }
      if (key.code === KEY_SHIFT) {
        relay('Shift', key.isDown());
        return;
      }
      if (!key.isDown() || key.repeat || key.ctrl || key.alt) {
        return;
      }
      handler.current(key.code);
    });
    globalEvents.on('window-blur', releaseAll);
    return () => {
      stop();
      globalEvents.off('window-blur', releaseAll);
      releaseAll();
      for (const code of BRIDGE_KEYS) {
        releaseHotKey(code);
      }
    };
  }, []);
};

const BridgeRadar = (props: {
  radius: number;
  onZoom: (radius: number) => void;
  follow: boolean;
}) => {
  const {
    act,
    data,
    post,
    selection,
    setSelection,
    marking,
    setMarking,
    flightLocked,
    armed,
    jumping,
  } = useBridge();
  const lastClick = useRef({ key: '', time: 0, x: 0, y: 0 });
  const isDouble = (key: string, x = 0, y = 0) => {
    const now = Date.now();
    const last = lastClick.current;
    const span = (data.cell_span || 100) * POINT_SLOP * (props.radius / 10);
    const same =
      last.key === key &&
      now - last.time < DOUBLE_CLICK &&
      Math.hypot(x - last.x, y - last.y) <= span;
    lastClick.current = { key: same ? '' : key, time: now, x, y };
    return same;
  };
  const runDefault = (next: Selection) => {
    const resolved = resolveSelection(data, next);
    const action = POST_ACTIONS[post][0];
    if (
      resolved &&
      actionAvailable(action, resolved, flightLocked) &&
      (!data.gunner || action === 'lock')
    ) {
      runAction(act, action, resolved);
    }
  };
  if (jumping) {
    return (
      <div className="Bridge__jump">
        ПРЫЖОК
        <small>сигнал вернётся по выходе из гиперпространства</small>
      </div>
    );
  }
  return (
    <OvermapRadar
      bare
      aimOnClick={false}
      showSelf={!!data.station_ship}
      outlines={data.radar_outlines}
      locked={!!data.radar_locked}
      tick={data.radar_tick}
      epoch={data.radar_epoch}
      peels={data.radar_peels}
      scatter={data.radar_scatter}
      dockTargets={data.radar_docks}
      dockPreview={data.dock_preview}
      selectedId={
        selection?.kind === 'object' || selection?.kind === 'dock'
          ? selection.id
          : undefined
      }
      onClear={() => {
        setSelection(null);
        setMarking(false);
      }}
      onSelectDock={(id) => {
        const next: Selection = { kind: 'dock', id };
        if (isDouble(`dock-${id}`)) {
          runDefault(next);
        }
        setSelection(next);
      }}
      onSelectObject={(id) => {
        const next: Selection = { kind: 'object', id };
        if (isDouble(`object-${id}`)) {
          runDefault(next);
        }
        setSelection(next);
      }}
      onSelectPoint={(x, y, ctrl) => {
        if (post === 'tac') {
          if (ctrl && armed.length) {
            act('radar_point', { x, y });
            return;
          }
          setSelection({ kind: 'point', x, y });
          return;
        }
        if (post !== 'nav' || data.gunner) {
          return;
        }
        if (marking) {
          setMarking(false);
          setSelection({ kind: 'point', x, y });
          if (!flightLocked) {
            act('nav_point', { x, y });
          }
          return;
        }
        if (isDouble('point', x, y) && !flightLocked) {
          act('nav_point', { x, y });
        }
        setSelection({ kind: 'point', x, y });
      }}
      shapes={data.radar_shapes || {}}
      contacts={data.radar || NO_CONTACTS}
      drifters={data.radar_drifters || NO_DRIFTERS}
      projectiles={data.radar_projectiles || NO_PROJECTILES}
      weaponArcs={post === 'tac' ? armed : NO_ARCS}
      facing={data.facing || 0}
      terrain={data.radar_terrain}
      world={data.radar_world}
      objects={data.objects}
      self={data.self_pos}
      sectorSize={data.sector_size}
      sectorNeighbors={data.sector_neighbors}
      cellSpan={data.cell_span}
      sectorId={data.sector_id}
      galaxy={data.galaxy}
      radius={props.radius}
      onZoom={props.onZoom}
      onReach={(reach) => {
        if (reach !== data.radar_reach) {
          act('helm_radar_reach', { reach });
        }
      }}
      followHeading={props.follow}
      dest={data.dest}
      hazardFields={data.hazard_fields || NO_FIELDS}
      lockedTarget={data.fire_target?.id}
      velocity={
        data.velocity_heading === null || data.velocity_heading === undefined
          ? undefined
          : [
              Math.sin((data.velocity_heading * Math.PI) / 180) * data.speed,
              Math.cos((data.velocity_heading * Math.PI) / 180) * data.speed,
            ]
      }
      stopDistance={(data.brake_distance || 0) * (data.cell_span || 0)}
    />
  );
};

const RouteLock = () => {
  const { act, data } = useBridge();
  const routes = data.programmed_routes || [];
  return (
    <div className="Bridge__lock">
      <div className="Bridge__lockPanel">
        <div className="Bridge__cap">РУЧНОЕ УПРАВЛЕНИЕ ЗАБЛОКИРОВАНО</div>
        <div className="Bridge__muted">
          Шаттл летает только по маршрутам поставщика.
        </div>
        {!!data.programmed_has_routes && (
          <div className="Bridge__stack">
            {routes.map((route) => (
              <Btn
                key={route.id}
                on={data.programmed_selected === route.id}
                disabled={data.programmed_busy}
                onClick={() => act('select_programmed', { id: route.id })}
              >
                {route.name}
              </Btn>
            ))}
            {data.programmed_busy ? (
              <div className="Bridge__muted">
                {data.programmed_windup
                  ? `Отправление через ${data.programmed_windup} с`
                  : `В пути, ${data.programmed_eta || ''}`}
              </div>
            ) : (
              <Btn
                on
                disabled={!routes.length}
                onClick={() =>
                  act('execute_programmed', { id: data.programmed_selected })
                }
              >
                ОТПРАВИТЬ
              </Btn>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export const Bridge = () => (
  <BridgeProvider>
    <BridgeBody />
  </BridgeProvider>
);

const BridgeBody = () => {
  const {
    act,
    data,
    post,
    posts,
    setPost,
    selection,
    setSelection,
    setMarking,
    jumping,
    routeLocked,
    flightLocked,
    radius,
    setRadius,
    follow,
    setFollow,
  } = useBridge();
  useBridgeKeys((code) => {
    if (code === KEY_ESCAPE) {
      setSelection(null);
      setMarking(false);
      return;
    }
    if (POST_KEYS[code]) {
      if (!data.gunner && !jumping && posts.includes(POST_KEYS[code])) {
        setPost(POST_KEYS[code]);
      }
      return;
    }
    if (code === KEY_T) {
      const targets = visibleObjects(data).filter(
        ({ object }) => object.id && TARGET_KINDS.includes(object.kind),
      );
      if (!targets.length) {
        return;
      }
      const current = targets.findIndex(
        ({ object }) =>
          selection?.kind === 'object' && object.id === selection.id,
      );
      const next = targets[(current + 1) % targets.length].object;
      setSelection({ kind: 'object', id: next.id! });
      if (post === 'tac') {
        act('lock_target', { id: next.id });
      }
      return;
    }
    if (code === KEY_G) {
      act('fire_salvo', salvoParams(selection));
      return;
    }
    if (code === KEY_H) {
      act('toggle_free_fire');
      return;
    }
    if (flightLocked) {
      return;
    }
    switch (code) {
      case KEY_R:
      case KEY_F:
        if (data.max_cruise) {
          setThrottle(
            act,
            data.max_cruise,
            Math.max(
              0,
              Math.min(4, throttleIndex(data) + (code === KEY_R ? 1 : -1)),
            ),
          );
        }
        return;
      case KEY_V:
        toggleHold(act, data, 'prograde');
        return;
      case KEY_B:
        toggleHold(act, data, 'retrograde');
        return;
      case KEY_C:
        toggleHold(act, data, 'current');
        return;
      case KEY_Z:
        act('toggle_drift_assist');
        return;
      case KEY_P:
        if (data.dest || data.autopilot) {
          act('toggle_autopilot');
        }
        return;
    }
  });
  const title = data.vessel_name
    ? `${data.gunner ? 'Наводчик' : 'Мостик'} — ${data.vessel_name}`
    : data.gunner
      ? 'Наводчик'
      : 'Мостик';
  const pod = !!data.is_pod;
  return (
    <OvermapFrame
      title={title}
      width={1240}
      height={900}
      linked={data.linked}
      onRelink={() => act('relink')}
    >
      <div
        className={classes([
          'Bridge',
          `Bridge--${post}`,
          data.phase === 'docked' && 'Bridge--docked',
        ])}
      >
        <TopStrip />
        <div className="Bridge__stage">
          <div className="Bridge__scope">
            <BridgeRadar radius={radius} onZoom={setRadius} follow={follow} />
          </div>
          <MotionCorner />
          {!jumping && (
            <ViewCorner
              radius={radius}
              onZoom={setRadius}
              follow={follow}
              onFollow={setFollow}
            />
          )}
          <SelectedCorner />
          <ContactsCorner />
          {routeLocked && <RouteLock />}
        </div>
        <div
          className={classes([
            'Bridge__console',
            pod && 'Bridge__console--pod',
            jumping && 'Bridge__console--locked',
          ])}
        >
          <ThrottleDeck />
          {!pod && <HeadingDeck />}
          <Deck
            title={MIDDLE_TITLES[post]}
            live
            off={routeLocked && post !== 'tac'}
          >
            {post === 'nav' && <NavDeck />}
            {post === 'tac' && <TacDeck />}
            {post === 'dock' && <DockDeck />}
          </Deck>
          {!pod && <SystemsDeck />}
        </div>
      </div>
    </OvermapFrame>
  );
};
