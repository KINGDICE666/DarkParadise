import { Icon } from 'tgui-core/components';
import { classes } from 'tgui-core/react';

import { bearingTo, cellsTo, decimal, degrees, travelText } from './bridgeMath';
import { Btn, Kbd, useBridge } from './parts';
import { kindIcon, visibleObjects } from './selection';

const QUICK_OBJECTS = 4;

const RoutePlate = () => {
  const { data } = useBridge();
  if (!data.dest || !data.dest_name) {
    return (
      <div className="Bridge__plate">
        <div className="Bridge__glyph">
          <Icon name="route" />
        </div>
        <div>
          <h3>Маршрут не задан</h3>
          <small>выберите цель на радаре и проложите курс</small>
        </div>
      </div>
    );
  }
  const cells = cellsTo(data, data.dest[0], data.dest[1]);
  return (
    <div className="Bridge__plate Bridge__plate--lit">
      <div className="Bridge__glyph">
        <Icon
          name={data.dest_relay ? 'satellite-dish' : 'location-crosshairs'}
        />
      </div>
      <div>
        <h3>{data.dest_name}</h3>
        <small>
          {data.dest_relay ? `в «${data.dest_relay}» · ` : ''}
          {decimal(cells)} кл · пеленг{' '}
          {degrees(bearingTo(data, data.dest[0], data.dest[1]))} ·{' '}
          {travelText(data, cells)} при {Math.round(data.cruise || 0)} м/с
        </small>
      </div>
    </div>
  );
};

const QuickPoints = () => {
  const { act, data, flightLocked, marking, setMarking } = useBridge();
  const objects = visibleObjects(data)
    .filter(({ object }) => object.id && object.kind !== 'unknown')
    .slice(0, QUICK_OBJECTS);
  const marks = (data.waypoints || []).filter(
    (mark) => !objects.some(({ object }) => object.name === mark.name),
  );
  const isDest = (x: number, y: number) =>
    !!data.dest && data.dest[0] === x && data.dest[1] === y;
  return (
    <div className="Bridge__chips">
      <button
        type="button"
        disabled={flightLocked}
        className={classes(['Bridge__chip', marking && 'Bridge__chip--on'])}
        title="Курс в точку следующего клика по радару"
        onClick={() => setMarking(!marking)}
      >
        + метка
      </button>
      {objects.map(({ object, cells }) => (
        <button
          key={object.id}
          type="button"
          disabled={flightLocked}
          className={classes([
            'Bridge__chip',
            data.navigation_target_id === object.id && 'Bridge__chip--on',
          ])}
          onClick={() =>
            act('nav_dest', {
              id: object.id,
              x: object.x,
              y: object.y,
              name: object.name,
            })
          }
        >
          <Icon name={kindIcon(object.kind)} /> {object.name}{' '}
          <em>{decimal(cells)}</em>
        </button>
      ))}
      {marks.map((mark) => (
        <button
          key={mark.name}
          type="button"
          disabled={flightLocked}
          className={classes([
            'Bridge__chip',
            isDest(mark.x, mark.y) && 'Bridge__chip--on',
          ])}
          onClick={() =>
            act('nav_dest', { x: mark.x, y: mark.y, name: mark.name })
          }
        >
          <Icon name="location-dot" /> {mark.name}{' '}
          <em>{decimal(cellsTo(data, mark.x, mark.y))}</em>
        </button>
      ))}
    </div>
  );
};

const Routes = () => {
  const { act, data } = useBridge();
  const routes = data.programmed_routes || [];
  if (!data.programmed_has_routes || data.programmed_locked || !routes.length) {
    return null;
  }
  return (
    <>
      <div className="Bridge__cap">
        АВТОМАРШРУТЫ
        {data.programmed_busy
          ? data.programmed_windup
            ? ` · отправление через ${data.programmed_windup} с`
            : ` · в пути ${data.programmed_eta || ''}`
          : ''}
      </div>
      <div className="Bridge__chips">
        {routes.map((route) => (
          <button
            key={route.id}
            type="button"
            disabled={!!data.programmed_busy}
            className="Bridge__chip"
            onClick={() => act('execute_programmed', { id: route.id })}
          >
            {route.name}
          </button>
        ))}
      </div>
    </>
  );
};

export const NavDeck = () => {
  const { act, data, flightLocked } = useBridge();
  const canFly = !flightLocked && !!data.dest;
  return (
    <div className="Bridge__mode">
      <div className="Bridge__stack Bridge__grow">
        <RoutePlate />
        <div className="Bridge__cap">БЫСТРЫЕ ТОЧКИ</div>
        <QuickPoints />
        <Routes />
        <div className="Bridge__keys Bridge__keys--foot">
          клик по радару — выбрать · двойной клик — проложить курс · ПКМ — снять
          выбор
        </div>
      </div>
      <div className="Bridge__stack Bridge__side">
        <button
          type="button"
          disabled={!canFly && !data.autopilot}
          className={classes([
            'Bridge__cta',
            'Bridge__grow',
            data.autopilot && 'Bridge__cta--lit',
          ])}
          onClick={() => act('toggle_autopilot')}
        >
          АВТОПИЛОТ
          <small>
            {data.autopilot
              ? data.autopilot_status || 'ведёт к цели'
              : data.dest
                ? 'выключен'
                : 'нет цели'}{' '}
            · <Kbd>P</Kbd>
          </small>
        </button>
        {data.programmed_cancellable ? (
          <Btn ghost onClick={() => act('cancel_programmed')}>
            ОТМЕНИТЬ АВТОМАРШРУТ
          </Btn>
        ) : null}
        <div className="Bridge__cols">
          <Btn
            ghost
            className="Bridge__grow"
            disabled={!data.dest || !!data.gunner}
            onClick={() => act('clear_dest')}
          >
            СБРОС
          </Btn>
          <Btn
            className="Bridge__grow"
            disabled={!data.can_relay_jump || flightLocked}
            title={data.relay_to ? `Прыжок в «${data.relay_to}»` : undefined}
            onClick={() => act('relay_jump')}
          >
            ПРЫЖОК
          </Btn>
        </div>
      </div>
    </div>
  );
};
