import { storage } from 'common/storage';
import { store } from '../events/store';
import {
  allChatAtom,
  chatLoadedAtom,
  chatPagesAtom,
  chatPagesRecordAtom,
  currentPageAtom,
  scrollTrackingAtom,
} from './atom';
import { MAX_PERSISTED_MESSAGES } from './constants';
import { canPageAcceptType, serializeMessage } from './model';
import { chatRenderer } from './renderer';
import type { StoredChatSettings } from './types';

chatRenderer.events.on(
  'batchProcessed',
  (countByType: Record<string, number>) => {
    // Use this flag to workaround unread messages caused by
    // loading them from storage. Side effect of that, is that
    // message count can not be trusted, only unread count.
    if (store.get(chatLoadedAtom)) {
      updateMessageCount(countByType);
    }
  },
);

function updateMessageCount(countByType: Record<string, number>): void {
  const pagesRecord = store.get(chatPagesRecordAtom);
  const pages = store.get(chatPagesAtom);
  const currentPage = store.get(currentPageAtom);
  const scrollTracking = store.get(scrollTrackingAtom);

  const draftpagesRecord = { ...pagesRecord };

  for (const pageId of pages) {
    const page = pagesRecord[pageId];
    let unreadCount = 0;

    for (const type in countByType) {
      /// Message does not belong here
      if (!canPageAcceptType(page, type)) continue;

      // Current page scroll tracked
      if (page === currentPage && scrollTracking) continue;

      // This page received the same message which we can read on the current
      // page
      if (page !== currentPage && canPageAcceptType(currentPage, type)) {
        continue;
      }
      unreadCount += countByType[type];
    }

    if (unreadCount > 0) {
      draftpagesRecord[page.id] = {
        ...page,
        unreadCount: page.unreadCount + unreadCount,
      };
    }
  }

  store.set(chatPagesRecordAtom, draftpagesRecord);
}

export async function saveChatToStorage(): Promise<void> {
  const chatSavingEnabled = await storage.get('chat-saving-enabled');
  if (chatSavingEnabled !== false) {
    saveChatMessages();
  }
  const allChat = store.get(allChatAtom);
  saveChatState(allChat);
}

let lastSavedMessage: unknown = null;
let lastSavedMessageCount = -1;
let lastSavedState = '';

function saveChatMessages(): void {
  const allMessages = chatRenderer.messages;
  const newest = allMessages[allMessages.length - 1];
  if (
    newest === lastSavedMessage &&
    allMessages.length === lastSavedMessageCount
  ) {
    return;
  }
  lastSavedMessage = newest;
  lastSavedMessageCount = allMessages.length;

  const fromIndex = Math.max(0, allMessages.length - MAX_PERSISTED_MESSAGES);

  const messages = allMessages
    .slice(fromIndex)
    .map((message) => serializeMessage(message));

  storage.processChatMessages(messages);
}

export function saveChatState(state: StoredChatSettings): void {
  // Avoid persisting frequently-changing unread counts.
  const pageById = Object.fromEntries(
    Object.entries(state.pageById).map(([id, page]) => [
      id,
      {
        ...page,
        unreadCount: 0,
      },
    ]),
  );

  const draft = {
    ...state,
    pageById,
  };
  const serialized = JSON.stringify(draft);
  if (serialized === lastSavedState) {
    return;
  }
  lastSavedState = serialized;
  storage.set('chat-state', draft);
}
