import { randomUUID } from "node:crypto";

export type LiveStreamRow = {
  id: string;
  title: string;
  description?: string;
  category?: string;
  tags?: string[];
  broadcasterId: string;
  broadcasterName: string;
  thumbnailUrl?: string;
  status: "live" | "ended";
  viewerCount: number;
  createdAt: string;
  endedAt?: string;
};

export type LiveStreamMessageRow = {
  id: string;
  streamId: string;
  content: string;
  createdAt: string;
  user: {
    id: string;
    name: string;
    nickname?: string;
    image?: string;
  };
};

const streams = new Map<string, LiveStreamRow>();
const messages = new Map<string, LiveStreamMessageRow[]>();
const viewers = new Map<string, Set<string>>();

export function getLiveStream(streamId: string): LiveStreamRow | undefined {
  return streams.get(streamId);
}

export function listLiveStreams(): LiveStreamRow[] {
  return [...streams.values()].filter((s) => s.status === "live");
}

export function upsertLiveStream(row: LiveStreamRow): LiveStreamRow {
  streams.set(row.id, row);
  return row;
}

export function endLiveStream(streamId: string): LiveStreamRow | undefined {
  const row = streams.get(streamId);
  if (!row) return undefined;
  row.status = "ended";
  row.endedAt = new Date().toISOString();
  row.viewerCount = 0;
  streams.set(streamId, row);
  viewers.delete(streamId);
  return row;
}

export function joinLiveStream(streamId: string, userId: string): number {
  let set = viewers.get(streamId);
  if (!set) {
    set = new Set();
    viewers.set(streamId, set);
  }
  set.add(userId);
  const row = streams.get(streamId);
  const count = set.size;
  if (row) {
    row.viewerCount = count;
    streams.set(streamId, row);
  }
  return count;
}

export function leaveLiveStream(streamId: string, userId: string): number {
  const set = viewers.get(streamId);
  if (!set) return streams.get(streamId)?.viewerCount ?? 0;
  set.delete(userId);
  const row = streams.get(streamId);
  const count = set.size;
  if (row) {
    row.viewerCount = count;
    streams.set(streamId, row);
  }
  return count;
}

export function listLiveStreamMessages(
  streamId: string,
  since?: string,
): LiveStreamMessageRow[] {
  const list = messages.get(streamId) ?? [];
  if (!since) return [...list];
  const t = Date.parse(since);
  if (Number.isNaN(t)) return [...list];
  return list.filter((m) => Date.parse(m.createdAt) > t);
}

export function addLiveStreamMessage(
  streamId: string,
  user: LiveStreamMessageRow["user"],
  content: string,
): LiveStreamMessageRow | null {
  const trimmed = content.trim();
  if (!trimmed) return null;
  const row = streams.get(streamId);
  if (!row || row.status !== "live") return null;
  let list = messages.get(streamId);
  if (!list) {
    list = [];
    messages.set(streamId, list);
  }
  const msg: LiveStreamMessageRow = {
    id: randomUUID(),
    streamId,
    content: trimmed.slice(0, 500),
    createdAt: new Date().toISOString(),
    user,
  };
  list.push(msg);
  if (list.length > 400) {
    messages.set(streamId, list.slice(-300));
  }
  return msg;
}
