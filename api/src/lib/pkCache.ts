/** In-memory PK cache — Redis ile değiştirilebilir arayüz. */

export type PkCacheEntry = {
  battleId: string;
  payload: Record<string, unknown>;
  expiresAt: number;
};

const store = new Map<string, PkCacheEntry>();
const TTL_MS = 30 * 60 * 1000;

function purgeExpired() {
  const now = Date.now();
  for (const [key, row] of store) {
    if (row.expiresAt <= now) store.delete(key);
  }
}

export const pkCache = {
  set(key: string, battleId: string, payload: Record<string, unknown>) {
    purgeExpired();
    store.set(key, {
      battleId,
      payload,
      expiresAt: Date.now() + TTL_MS,
    });
  },

  get(key: string): PkCacheEntry | null {
    purgeExpired();
    const row = store.get(key);
    if (!row) return null;
    if (row.expiresAt <= Date.now()) {
      store.delete(key);
      return null;
    }
    return row;
  },

  delete(key: string) {
    store.delete(key);
  },

  deleteByBattleId(battleId: string) {
    for (const [key, row] of store) {
      if (row.battleId === battleId) store.delete(key);
    }
  },
};

export function pkRoomCacheKey(roomId: string) {
  return `pk:room:${roomId}`;
}

export function pkStreamCacheKey(streamId: string) {
  return `pk:stream:${streamId}`;
}
