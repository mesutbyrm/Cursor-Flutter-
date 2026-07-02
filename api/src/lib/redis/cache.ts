import { kvGet, kvSet } from "./client";

/**
 * Önce Redis (veya bellek yedeği) kontrol edilir.
 * Yoksa loader çalışır, sonuç cache'e yazılır.
 */
export async function cacheGetOrSet<T>(
  key: string,
  ttlSeconds: number,
  loader: () => Promise<T>,
  serialize: (value: T) => string = JSON.stringify,
  deserialize: (raw: string) => T = JSON.parse,
): Promise<T> {
  const cached = await kvGet(key);
  if (cached != null) {
    try {
      return deserialize(cached);
    } catch {
      // Bozuk cache — yeniden yükle
    }
  }
  const value = await loader();
  await kvSet(key, serialize(value), ttlSeconds);
  return value;
}

export async function cacheInvalidate(key: string): Promise<void> {
  const { kvDel } = await import("./client");
  await kvDel(key);
}
