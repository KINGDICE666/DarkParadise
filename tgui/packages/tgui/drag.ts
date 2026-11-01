/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { createLogger } from 'common/logging';
import { isWebClient, storage } from 'common/storage';
import type { BooleanLike } from 'tgui-core/react';
import { vecAdd, vecMultiply, vecScale, vecSubtract } from 'tgui-core/vector';

type Point = [number, number];
type GeometryPayload = Partial<{
  pos: string;
  size: string;
}>;

const logger = createLogger('drag');
const webClient = isWebClient() && !!window.frameElement;
const pixelRatio = webClient ? 1 : (window.devicePixelRatio ?? 1);
let windowKey = Byond.windowId;
let dragging = false;
let resizing = false;
let screenOffset: Point = [0, 0];
let screenOffsetPromise: Promise<Point>;
let dragPointOffset: Point;
let resizeMatrix: Point;
let initialSize: Point;
let size: Point;

let winsetRaf: number | undefined;
let pendingWinset: GeometryPayload = {};
let lastSentWinset: GeometryPayload = {};

/** Expends all stored winset calls in a single call. */
function flushWinset(): void {
  winsetRaf = undefined;

  const payload: GeometryPayload = {};
  if (pendingWinset.pos && pendingWinset.pos !== lastSentWinset.pos) {
    payload.pos = pendingWinset.pos;
  }
  if (pendingWinset.size && pendingWinset.size !== lastSentWinset.size) {
    payload.size = pendingWinset.size;
  }

  pendingWinset = {};

  if (payload.pos || payload.size) {
    Byond.winset(Byond.windowId, payload);
    lastSentWinset = { ...lastSentWinset, ...payload };
  }
}

function scheduleWinset(): void {
  if (winsetRaf !== undefined) {
    return;
  }
  winsetRaf = requestAnimationFrame(flushWinset);
}

function flushWinsetNow(): void {
  if (winsetRaf !== undefined) {
    cancelAnimationFrame(winsetRaf);
    winsetRaf = undefined;
  }
  flushWinset();
}

// Set the window key
export function setWindowKey(key: string): void {
  windowKey = key;
}

// Get window position
export function getWindowPosition(): Point {
  if (webClient) {
    const rect = window.frameElement!.getBoundingClientRect();
    return [rect.left, rect.top];
  }
  return [window.screenLeft * pixelRatio, window.screenTop * pixelRatio];
}

// Get window size
export function getWindowSize(): Point {
  return [window.innerWidth * pixelRatio, window.innerHeight * pixelRatio];
}

function getPointerPosition(event: MouseEvent): Point {
  if (!webClient) {
    return [event.screenX * pixelRatio, event.screenY * pixelRatio];
  }
  if (event.view !== window) {
    return [event.clientX, event.clientY];
  }
  const rect = window.frameElement!.getBoundingClientRect();
  return [rect.left + event.clientX, rect.top + event.clientY];
}

function getPointerDocuments(): Document[] {
  return webClient ? [document, window.parent.document] : [document];
}

function formatPosition(vec: Point): string {
  return `${Math.round(vec[0])},${Math.round(vec[1])}`;
}

function formatSize(vec: Point): string {
  return `${Math.round(vec[0])}x${Math.round(vec[1])}`;
}

// Set window position
export function setWindowPosition(vec: Point): void {
  Byond.winset(Byond.windowId, {
    pos: formatPosition(vecAdd(vec, screenOffset) as Point),
  });
}

function setWindowPositionBatched(vec: Point): void {
  pendingWinset.pos = formatPosition(vecAdd(vec, screenOffset) as Point);
  scheduleWinset();
}

// Set window size
function setWindowSize(vec: Point): void {
  Byond.winset(Byond.windowId, {
    size: formatSize(vec),
  });
}

function setWindowSizeBatched(vec: Point): void {
  pendingWinset.size = formatSize(vec);
  scheduleWinset();
}

// Get screen position
function getScreenPosition(): Point {
  if (webClient) {
    return [0, 0];
  }
  return [0 - screenOffset[0], 0 - screenOffset[1]];
}

// Get screen size
function getScreenSize(): Point {
  if (webClient) {
    return [window.parent.innerWidth, window.parent.innerHeight];
  }
  return [
    window.screen.availWidth * pixelRatio,
    window.screen.availHeight * pixelRatio,
  ];
}

/**
 * Moves an item to the top of the recents array, and keeps its length
 * limited to the number in `limit` argument.
 *
 * Uses a strict equality check for comparisons.
 *
 * Returns new recents and an item which was trimmed.
 */
export function touchRecents(
  recents: string[],
  touchedItem: string,
  limit = 50,
): [string[], string | undefined] {
  const nextRecents: string[] = [touchedItem];
  let trimmedItem: string | undefined;
  for (let i = 0; i < recents.length; i++) {
    const item = recents[i];
    if (item === touchedItem) {
      continue;
    }
    if (nextRecents.length < limit) {
      nextRecents.push(item);
    } else {
      trimmedItem = item;
    }
  }
  return [nextRecents, trimmedItem];
}

// Store window geometry in local storage
export async function storeWindowGeometry(): Promise<void> {
  logger.log('storing geometry');
  const geometry = {
    pos: getWindowPosition(),
    size: getWindowSize(),
  };
  storage.set(windowKey, geometry);
  // Update the list of stored geometries
  const [geometries, trimmedKey] = touchRecents(
    (await storage.get('geometries')) || [],
    windowKey,
  );
  if (trimmedKey) {
    storage.remove(trimmedKey);
  }
  storage.set('geometries', geometries);
}

type RecallOptions = Partial<{
  pos: Point;
  size: Point;
  locked: BooleanLike;
  scale: BooleanLike;
}>;

// Recall window geometry from local storage and apply it
export async function recallWindowGeometry(
  options: RecallOptions = {},
): Promise<void> {
  let size = options.size;
  // Convert size from css-pixels to display-pixels
  if (options.scale && size) {
    size = [size[0] * pixelRatio, size[1] * pixelRatio];
  }
  // The size does not depend on the stored geometry, apply it right away
  if (size) {
    const areaAvailable = getScreenSize();
    size = [
      Math.min(areaAvailable[0], size[0]),
      Math.min(areaAvailable[1], size[1]),
    ];
    setWindowSize(size);
  }

  if (!options.scale && !webClient) {
    document.body.style.zoom = `${100 / window.devicePixelRatio}%`;
    document.documentElement.style.setProperty(
      '--scaling-amount',
      window.devicePixelRatio.toString(),
    );
  } else {
    document.body.style.zoom = '';
    document.documentElement.style.setProperty('--scaling-amount', null);
  }

  const geometry = await storage.get(windowKey);
  if (geometry) {
    logger.log('recalled geometry:', geometry);
  }
  // options.pos is assumed to already be in display-pixels
  let pos = geometry?.pos || options.pos;
  // Wait until screen offset gets resolved
  await screenOffsetPromise;
  if (webClient) {
    screenOffset = await measureScreenOffset();
  }
  const areaAvailable = getScreenSize();
  // Set window position
  if (pos) {
    // Constraint window position if monitor lock was set in preferences.
    if (size && (options.locked || webClient)) {
      pos = constraintPosition(pos, size)[1];
    }
    setWindowPosition(pos);
    // Set window position at the center of the screen.
  } else if (size) {
    pos = vecAdd(
      getScreenPosition(),
      vecScale(areaAvailable, 0.5),
      vecScale(size, -0.5),
    );
    setWindowPosition(pos);
  }
}

function isFrameRendered(): boolean {
  const rect = window.frameElement!.getBoundingClientRect();
  return (
    (rect.width > 0 || rect.height > 0) &&
    rect.right > 0 &&
    rect.bottom > 0 &&
    rect.left < window.parent.innerWidth &&
    rect.top < window.parent.innerHeight
  );
}

function measureScreenOffset(): Promise<Point> {
  if (webClient && !isFrameRendered()) {
    return Promise.resolve(screenOffset);
  }
  const windowPosition = getWindowPosition();
  return Byond.winget(Byond.windowId, 'pos').then((pos) =>
    Number.isFinite(pos?.x) && Number.isFinite(pos?.y)
      ? [pos.x - windowPosition[0], pos.y - windowPosition[1]]
      : screenOffset,
  );
}

// Setup draggable window
export async function setupDrag(): Promise<void> {
  // Calculate screen offset caused by the windows taskbar
  screenOffsetPromise = measureScreenOffset();
  screenOffset = await screenOffsetPromise;
  logger.debug('screen offset', screenOffset);
}

/**
 * Constraints window position to safe screen area, accounting for safe
 * margins which could be a system taskbar.
 */
function constraintPosition(pos: Point, size: Point): [boolean, Point] {
  const screenPos = getScreenPosition();
  const screenSize = getScreenSize();
  const nextPos: Point = [pos[0], pos[1]];
  let relocated = false;

  for (let i = 0; i < 2; i++) {
    const leftBoundary = screenPos[i];
    const rightBoundary = screenPos[i] + screenSize[i];
    if (pos[i] < leftBoundary) {
      nextPos[i] = leftBoundary;
      relocated = true;
    } else if (pos[i] + size[i] > rightBoundary) {
      nextPos[i] = rightBoundary - size[i];
      relocated = true;
    }
  }
  return [relocated, nextPos];
}

// Start dragging the window
export function dragStartHandler(event): void {
  logger.log('drag start');
  dragging = true;
  dragPointOffset = vecSubtract(
    getPointerPosition(event),
    getWindowPosition(),
  ) as Point;
  // Focus click target
  (event.target as HTMLElement)?.focus();
  for (const target of getPointerDocuments()) {
    target.addEventListener('mousemove', dragMoveHandler);
    target.addEventListener('mouseup', dragEndHandler);
  }
  dragMoveHandler(event);
}

// End dragging the window
function dragEndHandler(event): void {
  logger.log('drag end');
  dragMoveHandler(event);
  flushWinsetNow();
  for (const target of getPointerDocuments()) {
    target.removeEventListener('mousemove', dragMoveHandler);
    target.removeEventListener('mouseup', dragEndHandler);
  }
  dragging = false;
  storeWindowGeometry();
}

// Move the window while dragging
function dragMoveHandler(event: MouseEvent): void {
  if (!dragging) {
    return;
  }
  event.preventDefault();
  setWindowPositionBatched(
    vecSubtract(
      getPointerPosition(event),
      dragPointOffset,
    ) as Point,
  );
}

// Start resizing the window
export const resizeStartHandler =
  (x: number, y: number) =>
  (event: MouseEvent): void => {
    resizeMatrix = [x, y];
    logger.log('resize start', resizeMatrix);
    resizing = true;
    dragPointOffset = vecSubtract(
      getPointerPosition(event),
      getWindowPosition(),
    ) as Point;
    initialSize = getWindowSize();
    // Focus click target
    (event.target as HTMLElement)?.focus();
    for (const target of getPointerDocuments()) {
      target.addEventListener('mousemove', resizeMoveHandler);
      target.addEventListener('mouseup', resizeEndHandler);
    }
    resizeMoveHandler(event);
  };

// End resizing the window
function resizeEndHandler(event: MouseEvent): void {
  logger.log('resize end', size);
  resizeMoveHandler(event);
  flushWinsetNow();
  for (const target of getPointerDocuments()) {
    target.removeEventListener('mousemove', resizeMoveHandler);
    target.removeEventListener('mouseup', resizeEndHandler);
  }
  resizing = false;
  storeWindowGeometry();
}

// Move the window while resizing
function resizeMoveHandler(event: MouseEvent): void {
  if (!resizing) {
    return;
  }
  event.preventDefault();
  const currentOffset = vecSubtract(
    getPointerPosition(event),
    getWindowPosition(),
  );
  const delta = vecSubtract(currentOffset, dragPointOffset);
  // Extra 1x1 area is added to ensure the browser can see the cursor
  size = vecAdd(initialSize, vecMultiply(resizeMatrix, delta), [1, 1]) as [
    number,
    number,
  ];
  // Sane window size values
  size[0] = Math.max(size[0], 150 * pixelRatio);
  size[1] = Math.max(size[1], 50 * pixelRatio);
  setWindowSizeBatched(size);
}
