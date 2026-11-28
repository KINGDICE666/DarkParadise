import {
  createContext,
  type ReactNode,
  useContext,
  useEffect,
  useRef,
  useState,
} from 'react';
import { type BooleanLike, classes } from 'tgui-core/react';

import { useBackend } from '../../../backend';
import type { DockPick, HelmData, Post, Selection } from './types';

export const HOLD_TIME = 600;

export const SECTOR_ZOOM = 160;
const DOCK_ZOOM = 100;

const useBridgeView = (docked: boolean) => {
  const [post, setStoredPost] = useState<Post>(docked ? 'dock' : 'nav');
  const [selection, setSelection] = useState<Selection>(null);
  const [marking, setMarking] = useState(false);
  const [radius, setRadius] = useState(docked ? DOCK_ZOOM : SECTOR_ZOOM);
  const [follow, setFollow] = useState(false);
  const [dockPick, setDockPick] = useState<DockPick>(null);
  const setPost = (next: Post) => {
    setStoredPost(next);
    if (next === 'dock') {
      setRadius((current) => Math.min(current, DOCK_ZOOM));
    }
  };
  return {
    storedPost: post,
    setPost,
    selection,
    setSelection,
    marking,
    setMarking,
    radius,
    setRadius,
    follow,
    setFollow,
    dockPick,
    setDockPick,
  };
};

const BridgeView = createContext<ReturnType<typeof useBridgeView> | null>(null);

export const BridgeProvider = (props: { children: ReactNode }) => {
  const { data } = useBackend<HelmData>();
  const view = useBridgeView(data.phase === 'docked');
  return (
    <BridgeView.Provider value={view}>{props.children}</BridgeView.Provider>
  );
};

export const useBridge = () => {
  const { act, data } = useBackend<HelmData>();
  const view = useContext(BridgeView)!;
  const { storedPost } = view;
  const posts = availablePosts(data);
  const post: Post = data.gunner
    ? 'tac'
    : posts.includes(storedPost)
      ? storedPost
      : 'nav';
  const jumping = !!data.map_jammed && !data.radar_locked;
  const routeLocked = !!data.programmed_locked;
  const otherPilot = !!data.pilot_name && !data.piloting && !data.is_pod;
  const flightLocked =
    !!data.gunner ||
    jumping ||
    routeLocked ||
    !data.can_steer ||
    otherPilot ||
    data.phase === 'docked';
  return {
    ...view,
    act,
    data,
    post,
    posts,
    jumping,
    routeLocked,
    otherPilot,
    flightLocked,
    armed: (data.weapons || []).filter((weapon) => weapon.selected),
  };
};

export const availablePosts = (data: HelmData): Post[] => {
  if (!data.is_pod) {
    return ['nav', 'tac', 'dock'];
  }
  const posts: Post[] = ['nav'];
  if (data.weapons?.length) {
    posts.push('tac');
  }
  if (
    data.radar_docks?.length ||
    data.docks?.length ||
    data.can_stop ||
    data.can_undock
  ) {
    posts.push('dock');
  }
  return posts;
};

export const Kbd = (props: { children: ReactNode }) => (
  <kbd className="Bridge__kbd">{props.children}</kbd>
);

export const Deck = (props: {
  title: ReactNode;
  live?: boolean;
  off?: boolean;
  className?: string;
  children: ReactNode;
}) => (
  <section
    className={classes([
      'Bridge__deck',
      props.live && 'Bridge__deck--live',
      props.off && 'Bridge__deck--off',
      props.className,
    ])}
  >
    <div className="Bridge__deckBody">
      <h2 className="Bridge__deckTitle">{props.title}</h2>
      {props.children}
    </div>
  </section>
);

export const Btn = (props: {
  on?: BooleanLike;
  ghost?: boolean;
  disabled?: BooleanLike;
  title?: string;
  className?: string;
  onClick: () => void;
  children: ReactNode;
}) => (
  <button
    type="button"
    title={props.title}
    disabled={!!props.disabled}
    className={classes([
      'Bridge__btn',
      props.on && 'Bridge__btn--on',
      props.ghost && 'Bridge__btn--ghost',
      props.className,
    ])}
    onClick={props.onClick}
  >
    {props.children}
  </button>
);

export const Toggle = (props: {
  on?: BooleanLike;
  disabled?: BooleanLike;
  title?: string;
  onClick: () => void;
  children: ReactNode;
}) => (
  <button
    type="button"
    title={props.title}
    disabled={!!props.disabled}
    className={classes(['Bridge__toggle', props.on && 'Bridge__toggle--on'])}
    onClick={props.onClick}
  >
    <i />
    {props.children}
  </button>
);

export const HoldButton = (props: {
  className?: string;
  disabled?: BooleanLike;
  title?: string;
  onHold: () => void;
  children: ReactNode;
}) => {
  const [holding, setHolding] = useState(false);
  const timer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  const stop = () => {
    clearTimeout(timer.current);
    setHolding(false);
  };
  useEffect(() => () => clearTimeout(timer.current), []);
  return (
    <button
      type="button"
      title={props.title}
      disabled={!!props.disabled}
      className={classes([
        'Bridge__hold',
        holding && 'Bridge__hold--active',
        props.className,
      ])}
      onMouseDown={(event) => {
        if (event.button !== 0 || props.disabled) {
          return;
        }
        setHolding(true);
        timer.current = setTimeout(() => {
          setHolding(false);
          props.onHold();
        }, HOLD_TIME);
      }}
      onMouseUp={stop}
      onMouseLeave={stop}
    >
      <i className="Bridge__holdFill" />
      <span className="Bridge__holdLabel">{props.children}</span>
    </button>
  );
};
