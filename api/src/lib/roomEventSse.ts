import type { Response } from "express";
import { resolveRoomId } from "./chatRoomStore";

const subscribers = new Map<string, Set<Response>>();

function roomKey(roomId: string) {
  return resolveRoomId(roomId);
}

export function subscribeRoomEventSse(roomId: string, res: Response) {
  const key = roomKey(roomId);
  let set = subscribers.get(key);
  if (!set) {
    set = new Set();
    subscribers.set(key, set);
  }
  set.add(res);
}

export function unsubscribeRoomEventSse(roomId: string, res: Response) {
  const key = roomKey(roomId);
  const set = subscribers.get(key);
  if (!set) return;
  set.delete(res);
  if (set.size === 0) subscribers.delete(key);
}

export function emitRoomEventSse(
  roomId: string,
  payload: Record<string, unknown>,
) {
  const key = roomKey(roomId);
  const set = subscribers.get(key);
  if (!set || set.size === 0) return;
  const full = {
    ...payload,
    type: "room_event",
    roomId: key,
  };
  const line = `data: ${JSON.stringify(full)}\n\n`;
  for (const res of set) {
    try {
      res.write(line);
    } catch {
      set.delete(res);
    }
  }
}
