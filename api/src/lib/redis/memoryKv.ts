/**
 * Bellek içi KV — Redis yokken veya geçici kesintide şeffaf yedek.
 * TTL destekli; süresi dolan anahtarlar okuma sırasında temizlenir.
 */

type MemEntry = { value: string; expiresAt?: number };

const store = new Map<string, MemEntry>();

function purgeExpired(key: string, entry: MemEntry): boolean {
  if (entry.expiresAt != null && entry.expiresAt <= Date.now()) {
    store.delete(key);
    return true;
  }
  return false;
}

export const memoryKv = {
  get(key: string): string | null {
    const row = store.get(key);
    if (!row) return null;
    if (purgeExpired(key, row)) return null;
    return row.value;
  },

  set(key: string, value: string, ttlSeconds?: number) {
    store.set(key, {
      value,
      expiresAt: ttlSeconds ? Date.now() + ttlSeconds * 1000 : undefined,
    });
  },

  del(key: string) {
    store.delete(key);
  },

  incr(key: string): number {
    const current = Number(memoryKv.get(key) ?? "0");
    const next = current + 1;
    memoryKv.set(key, String(next));
    return next;
  },

  expire(key: string, ttlSeconds: number) {
    const row = store.get(key);
    if (!row) return;
    row.expiresAt = Date.now() + ttlSeconds * 1000;
    store.set(key, row);
  },

  lpush(key: string, value: string) {
    const raw = memoryKv.get(key);
    const list: string[] = raw ? JSON.parse(raw) : [];
    list.unshift(value);
    memoryKv.set(key, JSON.stringify(list));
    return list.length;
  },

  rpush(key: string, value: string) {
    const raw = memoryKv.get(key);
    const list: string[] = raw ? JSON.parse(raw) : [];
    list.push(value);
    memoryKv.set(key, JSON.stringify(list));
    return list.length;
  },

  lrange(key: string, start: number, stop: number): string[] {
    const raw = memoryKv.get(key);
    const list: string[] = raw ? JSON.parse(raw) : [];
    const end = stop < 0 ? list.length + stop + 1 : stop + 1;
    return list.slice(start, end);
  },

  lpop(key: string): string | null {
    const raw = memoryKv.get(key);
    const list: string[] = raw ? JSON.parse(raw) : [];
    if (list.length === 0) return null;
    const item = list.shift()!;
    memoryKv.set(key, JSON.stringify(list));
    return item;
  },

  sadd(key: string, member: string) {
    const raw = memoryKv.get(key);
    const set = new Set<string>(raw ? JSON.parse(raw) : []);
    set.add(member);
    memoryKv.set(key, JSON.stringify([...set]));
  },

  srem(key: string, member: string) {
    const raw = memoryKv.get(key);
    const set = new Set<string>(raw ? JSON.parse(raw) : []);
    set.delete(member);
    memoryKv.set(key, JSON.stringify([...set]));
  },

  smembers(key: string): string[] {
    const raw = memoryKv.get(key);
    return raw ? JSON.parse(raw) : [];
  },

  zincrby(key: string, increment: number, member: string) {
    const raw = memoryKv.get(key);
    const map = new Map<string, number>(
      raw ? Object.entries(JSON.parse(raw) as Record<string, number>) : [],
    );
    map.set(member, (map.get(member) ?? 0) + increment);
    memoryKv.set(key, JSON.stringify(Object.fromEntries(map)));
  },

  zrevrange(key: string, start: number, stop: number): string[] {
    const raw = memoryKv.get(key);
    const map = new Map<string, number>(
      raw ? Object.entries(JSON.parse(raw) as Record<string, number>) : [],
    );
    const sorted = [...map.entries()].sort((a, b) => b[1] - a[1]);
    const end = stop < 0 ? sorted.length + stop + 1 : stop + 1;
    return sorted.slice(start, end).map(([id]) => id);
  },

  hset(key: string, field: string, value: string) {
    const raw = memoryKv.get(key);
    const obj: Record<string, string> = raw ? JSON.parse(raw) : {};
    obj[field] = value;
    memoryKv.set(key, JSON.stringify(obj));
  },

  hget(key: string, field: string): string | null {
    const raw = memoryKv.get(key);
    if (!raw) return null;
    const obj = JSON.parse(raw) as Record<string, string>;
    return obj[field] ?? null;
  },

  hgetall(key: string): Record<string, string> {
    const raw = memoryKv.get(key);
    return raw ? JSON.parse(raw) : {};
  },

  hdel(key: string, field: string) {
    const raw = memoryKv.get(key);
    if (!raw) return;
    const obj = JSON.parse(raw) as Record<string, string>;
    delete obj[field];
    memoryKv.set(key, JSON.stringify(obj));
  },
};
