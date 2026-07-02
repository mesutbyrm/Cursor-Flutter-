/** PK önbelleği — Redis + bellek L1 (çoklu instance uyumlu). */

import { kvDel, kvGet, kvSet } from "./redis/client";
import { RedisTTL } from "./redis/keys";

export type PkCacheEntry = {
  battleId: string;
  payload: Record<string, unknown>;
  expiresAt: number;
};

const memory = new Map<string, PkCacheEntry>();
const TTL_MS = RedisTTL.pkCache * 1000;

function purgeExpired() {
  const now = Date.now();
  for (const [key, row] of memory) {
    if (row.expiresAt <= now) memory.delete(key);
  }
}

function parseEntry(raw: string | null): PkCacheEntry | null {
  if (!raw) return null;
  try {
    const row = JSON.parse(raw) as PkCacheEntry;
    if (row.expiresAt <= Date.now()) return null;
    return row;
  } catch {
    return null;
  }
}

export const pkCache = {
  set(key: string, battleId: string, payload: Record<string, unknown>) {
    purgeExpired();
    const entry: PkCacheEntry = {
      battleId,
      payload,
      expiresAt: Date.now() + TTL_MS,
    };
    memory.set(key, entry);
    void kvSet(key, JSON.stringify(entry), RedisTTL.pkCache);
  },

  get(key: string): PkCacheEntry | null {
    purgeExpired();
    const row = memory.get(key);
    if (row && row.expiresAt > Date.now()) return row;
    return null;
  },

  async getAsync(key: string): Promise<PkCacheEntry | null> {
    const local = pkCache.get(key);
    if (local) return local;
    const remote = parseEntry(await kvGet(key));
    if (remote) memory.set(key, remote);
    return remote;
  },

  delete(key: string) {
    memory.delete(key);
    void kvDel(key);
  },

  deleteByBattleId(battleId: string) {
    for (const [key, row] of memory) {
      if (row.battleId === battleId) {
        memory.delete(key);
        void kvDel(key);
      }
    }
  },
};

export function pkRoomCacheKey(roomId: string) {
  return `pk:room:${roomId}`;
}

export function pkStreamCacheKey(streamId: string) {
  return `pk:stream:${streamId}`;
}
