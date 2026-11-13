import { useState } from 'react';
import { classes } from 'tgui-core/react';

import { Kbd, useBridge } from './parts';
import type { HelmData, Post } from './types';

const NOTICE_FADE = 20;

const POST_INFO: Record<Post, [string, string, string]> = {
  nav: ['НАВИГАЦИЯ', 'курс и маршрут', '1'],
  tac: ['БОЙ', 'цели и орудия', '2'],
  dock: ['СТЫКОВКА', 'шлюзы и заход', '3'],
};

const phaseText = (data: HelmData) => {
  switch (data.phase) {
    case 'route':
      return 'по маршруту';
    case 'relay':
      return 'прыжок';
    case 'docked':
      return 'пристыкован';
    case 'transit':
      return 'гиперпространство';
    default:
      if (data.dock_aligning) {
        return 'стыковка';
      }
      return data.local_space ? 'у объекта' : 'в полёте';
  }
};

const Ticker = () => {
  const { data } = useBridge();
  const notice = data.notice;
  if (notice && notice.age < NOTICE_FADE) {
    return (
      <div
        className={classes([
          'Bridge__ticker',
          notice.tone && `Bridge__ticker--${notice.tone}`,
        ])}
      >
        <span className="Bridge__tag">{notice.origin || 'МОСТИК'}</span>
        <span className="Bridge__tickerText">{notice.text}</span>
      </div>
    );
  }
  if (!data.can_steer && data.thrust_hint) {
    return (
      <div className="Bridge__ticker Bridge__ticker--warn">
        <span className="Bridge__tag">ДВИГАТЕЛИ</span>
        <span className="Bridge__tickerText">{data.thrust_hint}</span>
      </div>
    );
  }
  if (data.autopilot && data.autopilot_status) {
    return (
      <div className="Bridge__ticker Bridge__ticker--quiet">
        <span className="Bridge__tag">АВТОПИЛОТ</span>
        <span className="Bridge__tickerText">{data.autopilot_status}</span>
      </div>
    );
  }
  return (
    <div className="Bridge__ticker Bridge__ticker--quiet">
      <span className="Bridge__tickerText">Мостик на связи</span>
    </div>
  );
};

const EnginePanel = (props: { onClose: () => void }) => {
  const { act, data } = useBridge();
  return (
    <div className="Bridge__engines">
      <div className="Bridge__cap">ДВИГАТЕЛИ</div>
      {data.engines.map((engine) => (
        <div key={engine.ref} className="Bridge__engineRow">
          <span>
            {engine.name}
            <small>
              {engine.status} · тяга {engine.thrust}
              {engine.heat ? ` · ${engine.heat}°` : ''}
            </small>
          </span>
          <button
            type="button"
            className={classes(['Bridge__btn', engine.on && 'Bridge__btn--on'])}
            disabled={!!data.gunner}
            onClick={() => act('toggle_engine', { ref: engine.ref })}
          >
            {engine.on ? 'ВКЛ' : 'ВЫКЛ'}
          </button>
        </div>
      ))}
      {!data.engines.length && (
        <div className="Bridge__muted">Двигателей на борту нет.</div>
      )}
      <button
        type="button"
        className="Bridge__btn Bridge__btn--ghost"
        onClick={props.onClose}
      >
        ЗАКРЫТЬ
      </button>
    </div>
  );
};

export const TopStrip = () => {
  const { data, post, posts, setPost, jumping } = useBridge();
  const [enginesOpen, setEnginesOpen] = useState(false);
  const working = data.engines.filter((engine) => engine.on).length;
  const shield = data.shield;
  const transmitting = data.transponder
    ? data.transponder.broadcasting
    : data.broadcasting;
  return (
    <div className="Bridge__strip">
      <div className="Bridge__ident">
        <b>{(data.vessel_name || '').toUpperCase()}</b>
        <small>
          {data.sector_name || '—'} · клетка {data.x}:{data.y} ·{' '}
          {phaseText(data)}
        </small>
      </div>
      <Ticker />
      <div className="Bridge__pips">
        <button
          type="button"
          className="Bridge__pip"
          title="Список двигателей"
          onClick={() => setEnginesOpen(!enginesOpen)}
        >
          ДВИГАТЕЛИ
          <b
            className={
              working === data.engines.length && working
                ? 'Bridge__good'
                : 'Bridge__warnText'
            }
          >
            {working} / {data.engines.length}
          </b>
        </button>
        <div className="Bridge__pip">
          ЩИТ
          <b className={shield?.active ? 'Bridge__shieldText' : undefined}>
            {shield && shield.capacity > 0
              ? `${Math.round((shield.charge / shield.capacity) * 100)} %`
              : '—'}
          </b>
        </div>
        <div className="Bridge__pip">
          ТРАНСПОНДЕР
          <b>{transmitting ? 'в эфире' : 'молчит'}</b>
        </div>
      </div>
      {data.gunner ? (
        <div className="Bridge__posts">
          <div className="Bridge__post Bridge__post--tac Bridge__post--on">
            <b>НАВОДЧИК</b>
            <small>цели и орудия</small>
          </div>
        </div>
      ) : (
        <div className="Bridge__posts">
          {(Object.keys(POST_INFO) as Post[]).map((key) => {
            const [title, sub, hotkey] = POST_INFO[key];
            return (
              <button
                key={key}
                type="button"
                disabled={jumping || !posts.includes(key)}
                className={classes([
                  'Bridge__post',
                  `Bridge__post--${key}`,
                  post === key && 'Bridge__post--on',
                ])}
                onClick={() => setPost(key)}
              >
                <b>{title}</b>
                <small>{sub}</small>
                <Kbd>{hotkey}</Kbd>
              </button>
            );
          })}
        </div>
      )}
      {enginesOpen && <EnginePanel onClose={() => setEnginesOpen(false)} />}
    </div>
  );
};
