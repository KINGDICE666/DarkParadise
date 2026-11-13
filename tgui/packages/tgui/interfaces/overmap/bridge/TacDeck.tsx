import { Icon } from 'tgui-core/components';
import { classes } from 'tgui-core/react';

import { decimal, weaponState } from './bridgeMath';
import { Kbd, useBridge } from './parts';
import type { Weapon } from './types';

const AMMO_SEGMENTS = 6;

const WeaponCard = (props: { weapon: Weapon }) => {
  const { act } = useBridge();
  const { weapon } = props;
  const [label, tone] = weaponState(weapon);
  const reload =
    weapon.cooldown > 0 && weapon.cooldown_max
      ? 1 - weapon.cooldown / weapon.cooldown_max
      : 1;
  const ammoPart = weapon.max_ammo ? (weapon.ammo || 0) / weapon.max_ammo : 1;
  const filled = Math.round(ammoPart * AMMO_SEGMENTS);
  return (
    <div
      role="button"
      tabIndex={-1}
      className={classes([
        'Bridge__gun',
        weapon.selected && 'Bridge__gun--armed',
      ])}
      title={weapon.selected ? 'Снять с залпа' : 'Взвести орудие'}
      onClick={() => act('select_weapon', { id: weapon.id })}
    >
      <b>{weapon.name}</b>
      <small className={`Bridge__gunState--${tone}`}>{label}</small>
      <div
        className={classes(['Bridge__bar', reload < 1 && 'Bridge__bar--wait'])}
      >
        <i style={{ width: `${Math.max(0, Math.min(1, reload)) * 100}%` }} />
      </div>
      <div className="Bridge__ammo">
        {weapon.max_ammo ? (
          Array.from({ length: AMMO_SEGMENTS }, (_, index) => (
            <i
              key={index}
              className={index < filled ? undefined : 'Bridge__ammo--empty'}
            />
          ))
        ) : (
          <i className="Bridge__ammo--grid" />
        )}
      </div>
      <footer>
        <span>
          {weapon.max_ammo
            ? `${weapon.ammo || 0} / ${weapon.max_ammo}`
            : 'от сети'}
        </span>
        {weapon.turret && weapon.kind === 'autocannon' ? (
          <button
            type="button"
            className={classes([
              'Bridge__gunAuto',
              weapon.auto && 'Bridge__good',
            ])}
            title="ПРО: сбивать подлетающие торпеды"
            onClick={(event) => {
              event.stopPropagation();
              act('weapon_auto', { id: weapon.id });
            }}
          >
            ПРО {weapon.auto ? 'ВКЛ' : 'ВЫКЛ'}
          </button>
        ) : (
          <span>{weapon.arc}°</span>
        )}
      </footer>
    </div>
  );
};

export const TacDeck = () => {
  const { act, data, armed } = useBridge();
  const weapons = data.weapons || [];
  const target = data.fire_target;
  const ready = armed.filter((weapon) => weaponState(weapon)[1] === 'ok');
  const hot = !!target && ready.length > 0;
  return (
    <div className="Bridge__mode Bridge__mode--column">
      <div className="Bridge__firebar">
        <div
          className={classes(['Bridge__plate', target && 'Bridge__plate--lit'])}
        >
          <div className="Bridge__glyph Bridge__glyph--danger">
            <Icon name={target ? 'crosshairs' : 'circle-dot'} />
          </div>
          <div>
            <h3>{target ? target.name : 'Цель не захвачена'}</h3>
            <small>
              {target
                ? `${decimal(target.distance)} кл · ${decimal(target.speed)} м/с${target.shield ? ` · щит ${Math.round(target.shield * 100)} %` : ''}`
                : 'двойной клик по кораблю на радаре — захват'}
            </small>
          </div>
          {!!target && (
            <button
              type="button"
              className="Bridge__cardClose"
              title="Сбросить захват"
              onClick={() => act('clear_target')}
            >
              ✕
            </button>
          )}
        </div>
        <div className="Bridge__seg Bridge__seg--column">
          <button
            type="button"
            className={!data.free_fire ? 'Bridge__seg--on' : undefined}
            onClick={() => data.free_fire && act('toggle_free_fire')}
          >
            ПО КОМАНДЕ
          </button>
          <button
            type="button"
            className={data.free_fire ? 'Bridge__seg--on' : undefined}
            title="Взведённые орудия сами стреляют по цели, как только готовы"
            onClick={() => !data.free_fire && act('toggle_free_fire')}
          >
            ПО ГОТОВНОСТИ <Kbd>H</Kbd>
          </button>
        </div>
        <button
          type="button"
          disabled={!hot}
          className={classes([
            'Bridge__cta',
            'Bridge__salvo',
            hot && 'Bridge__salvo--hot',
          ])}
          onClick={() => act('fire_salvo')}
        >
          ЗАЛП
          <small>
            готово {ready.length} из {armed.length} · <Kbd>G</Kbd>
          </small>
        </button>
      </div>
      {weapons.length ? (
        <div className="Bridge__guns">
          {weapons.map((weapon) => (
            <WeaponCard key={weapon.id} weapon={weapon} />
          ))}
        </div>
      ) : (
        <div className="Bridge__empty">
          Орудий нет. Щиты и захват цели работают.
        </div>
      )}
      <div className="Bridge__keys Bridge__keys--foot">
        карточка — взвести · <Kbd>CTRL</Kbd>+клик — огонь в точку · <Kbd>T</Kbd>{' '}
        цель
      </div>
    </div>
  );
};
