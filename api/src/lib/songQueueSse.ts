import type { Response } from "express";

export type SongSseEventType =
  | "song_started"
  | "song_paused"
  | "song_resumed"
  | "song_finished"
  | "queue_updated"
  | "song_removed";

export type SongSsePayload = {
  type: SongSseEventType;
  roomId: string;
  serverTime: number;
  currentSong?: Record<string, unknown> | null;
  queue?: Record<string, unknown>[];
  queueId?: string;
  elapsed?: number;
  paused?: boolean;
};

const subscribers = new Map<string, Set<Response>>();

function roomKey(roomId: string) {
  return roomId.trim();
}

export function subscribeSongSse(roomId: string, res: Response) {
  const key = roomKey(roomId);
  let set = subscribers.get(key);
  if (!set) {
    set = new Set();
    subscribers.set(key, set);
  }
  set.add(res);
}

export function unsubscribeSongSse(roomId: string, res: Response) {
  const key = roomKey(roomId);
  const set = subscribers.get(key);
  if (!set) return;
  set.delete(res);
  if (set.size === 0) subscribers.delete(key);
}

export function emitSongSse(roomId: string, payload: Omit<SongSsePayload, "serverTime">) {
  const key = roomKey(roomId);
  const set = subscribers.get(key);
  if (!set || set.size === 0) return;
  const full: SongSsePayload = { ...payload, serverTime: Date.now() };
  const line = `data: ${JSON.stringify(full)}\n\n`;
  for (const res of set) {
    try {
      res.write(line);
    } catch {
      set.delete(res);
    }
  }
}

export function songSseSubscriberCount(roomId: string) {
  return subscribers.get(roomKey(roomId))?.size ?? 0;
}
