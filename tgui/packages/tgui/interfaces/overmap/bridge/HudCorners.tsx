import { Icon } from 'tgui-core/components';
import { classes } from 'tgui-core/react';

import {
  clampRadarZoom,
  formatRadarDistance,
  GALAXY_SLOT,
  galaxyBandFor,
  RADAR_TILE_SPAN,
  RADAR_ZOOM_STEP,
  radarZoomCeiling,
} from '../OvermapRadar';
import { decimal, degrees, isHostile } from './bridgeMath';
import { SECTOR_ZOOM, useBridge } from './parts';
import {
  ACTION_LABELS,
  actionAvailable,
  contactNote,
  kindIcon,
  POST_ACTIONS,
  resolveSelection,
  runAction,
  visibleObjects,
} from './selection';

const CONTACT_ROWS = 7;

export const MotionCorner = () => {
  const { data, otherPilot } = useBridge();
  return (
    <div className="Bridge__hud Bridge__hud--tl">
      <div className="Bridge__cap">ХОД</div>
      <div className="Bridge__speed">
        <span className="Bridge__speedValue">{decimal(data.speed || 0)}</span>
        <span className="Bridge__speedUnit">М/С</span>
        <span className="Bridge__speedSet">
          задано
          <b>{data.held_brake ? 'стоп' : Math.round(data.cruise || 0)}</b>
        </span>
      </div>
      <div className="Bridge__readouts">
        <div className="Bridge__ro">
          <small>КУРС</small>
          <b>{degrees(data.nose ?? data.facing)}</b>
        </div>
        <div className="Bridge__ro">
          <small>ВЕКТОР</small>
          <b className="Bridge__warnText">{degrees(data.velocity_heading)}</b>
        </div>
        <div className="Bridge__ro">
          <small>ТОРМ. ПУТЬ</small>
          <b>{decimal(data.brake_distance || 0)} кл</b>
        </div>
      </div>
      {otherPilot && (
        <div className="Bridge__pilot">
          За штурвалом: <b>{data.pilot_name}</b>
        </div>
      )}
      {!data.gunner &&
        !otherPilot &&
        !data.piloting &&
        !data.is_pod &&
        data.phase === 'flight' && (
          <div className="Bridge__pilot">
            Подойдите к консоли вплотную, чтобы вести корабль.
          </div>
        )}
    </div>
  );
};

export const ViewCorner = (props: {
  radius: number;
  onZoom: (radius: number) => void;
  follow: boolean;
  onFollow: (follow: boolean) => void;
}) => {
  const { data } = useBridge();
  const { radius, onZoom, follow, onFollow } = props;
  const cellSpan = data.cell_span || RADAR_TILE_SPAN;
  const sectorSpan = Math.max(cellSpan * (data.sector_size || 0), cellSpan * 4);
  const galaxyRadius = galaxyBandFor(sectorSpan);
  const galaxy = !!data.radar_locked || radius > galaxyRadius;
  const ceiling = radarZoomCeiling(sectorSpan);
  const slot = Math.max(GALAXY_SLOT, sectorSpan * 0.6);
  return (
    <div className="Bridge__hud Bridge__hud--bl">
      <div className="Bridge__viewbar">
        <div className="Bridge__seg">
          <button
            type="button"
            className={!galaxy ? 'Bridge__seg--on' : undefined}
            onClick={() => onZoom(SECTOR_ZOOM)}
          >
            СЕКТОР
          </button>
          <button
            type="button"
            className={galaxy ? 'Bridge__seg--on' : undefined}
            onClick={() => onZoom(galaxyRadius * 1.15)}
          >
            ГАЛАКТИКА
          </button>
        </div>
        <div className="Bridge__seg">
          <button
            type="button"
            className={!follow ? 'Bridge__seg--on' : undefined}
            onClick={() => onFollow(false)}
          >
            СЕВЕР
          </button>
          <button
            type="button"
            className={follow ? 'Bridge__seg--on' : undefined}
            onClick={() => onFollow(true)}
          >
            КУРС
          </button>
        </div>
        <div className="Bridge__seg">
          <button
            type="button"
            title="Отдалить"
            onClick={() =>
              onZoom(clampRadarZoom(radius * RADAR_ZOOM_STEP, ceiling))
            }
          >
            −
          </button>
          <button
            type="button"
            title="Приблизить"
            onClick={() =>
              onZoom(clampRadarZoom(radius / RADAR_ZOOM_STEP, ceiling))
            }
          >
            +
          </button>
        </div>
      </div>
      <div className="Bridge__scale">
        <i />
        радиус{' '}
        {galaxy
          ? `${decimal(radius / slot)} сект.`
          : formatRadarDistance(radius, cellSpan).replace('.', ',')}{' '}
        · колесо мыши — масштаб
      </div>
    </div>
  );
};

export const SelectedCorner = () => {
  const { act, data, post, selection, setSelection, flightLocked } =
    useBridge();
  const resolved = resolveSelection(data, selection);
  if (!resolved) {
    return null;
  }
  const actions = POST_ACTIONS[post];
  return (
    <div className="Bridge__hud Bridge__hud--tr">
      <div className="Bridge__cap">ВЫБРАНО</div>
      <div className="Bridge__card">
        <header>
          <div
            className={classes([
              'Bridge__glyph',
              resolved.danger && 'Bridge__glyph--danger',
            ])}
          >
            <Icon name={resolved.icon} />
          </div>
          <div className="Bridge__cardTitle">
            <h3>{resolved.name}</h3>
            <small>{resolved.sub}</small>
          </div>
          <button
            type="button"
            className="Bridge__cardClose"
            title="Снять выбор (Esc, ПКМ по радару)"
            onClick={() => setSelection(null)}
          >
            ✕
          </button>
        </header>
        <dl>
          <div>
            <dt>ДАЛЬНОСТЬ</dt>
            <dd>{resolved.range}</dd>
          </div>
          <div>
            <dt>ПЕЛЕНГ</dt>
            <dd>{degrees(resolved.bearing)}</dd>
          </div>
          <div>
            <dt>{resolved.third[0]}</dt>
            <dd>{resolved.third[1]}</dd>
          </div>
        </dl>
        <div className="Bridge__acts">
          {actions.map((action, index) => (
            <button
              key={action}
              type="button"
              className={index === 0 ? 'Bridge__acts--def' : undefined}
              disabled={
                !actionAvailable(action, resolved, flightLocked) ||
                (!!data.gunner && action !== 'lock')
              }
              onClick={() => runAction(act, action, resolved)}
            >
              {ACTION_LABELS[action]}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
};

export const ContactsCorner = () => {
  const { data, selection, setSelection } = useBridge();
  const contacts = visibleObjects(data);
  return (
    <div className="Bridge__hud Bridge__hud--br">
      <div className="Bridge__cap">КОНТАКТЫ · {contacts.length}</div>
      <div className="Bridge__contacts">
        {contacts.slice(0, CONTACT_ROWS).map(({ object, cells }) => (
          <button
            key={object.id || `${object.name}-${object.x}-${object.y}`}
            type="button"
            className={classes([
              'Bridge__row',
              isHostile(object) && 'Bridge__row--danger',
              selection?.kind === 'object' &&
                selection.id === object.id &&
                'Bridge__row--sel',
            ])}
            disabled={!object.id}
            onClick={() =>
              object.id && setSelection({ kind: 'object', id: object.id })
            }
          >
            <Icon
              name={
                object.distress ? 'triangle-exclamation' : kindIcon(object.kind)
              }
              style={
                isHostile(object) ? undefined : { color: object.color || '' }
              }
            />
            <span>
              {object.name}
              <small>{contactNote(data, object, cells).toUpperCase()}</small>
            </span>
            <em>{decimal(cells)}</em>
          </button>
        ))}
        {!contacts.length && (
          <div className="Bridge__muted">Сенсоры ничего не видят.</div>
        )}
      </div>
    </div>
  );
};
