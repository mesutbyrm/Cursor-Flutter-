import { createHash } from "node:crypto";
import { cacheGetOrSet } from "./cache";
import { RedisKeys, RedisTTL } from "./keys";

export function aiFortuneCacheKey(parts: Record<string, unknown>): string {
  const stable = JSON.stringify(parts, Object.keys(parts).sort());
  return createHash("sha256").update(stable).digest("hex").slice(0, 32);
}

export async function aiFortuneCacheGet<T>(
  parts: Record<string, unknown>,
): Promise<T | null> {
  const { kvGet } = await import("./client");
  const key = RedisKeys.cache.aiFortune(aiFortuneCacheKey(parts));
  const raw = await kvGet(key);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as T;
  } catch {
    return null;
  }
}

export async function aiFortuneCacheSet<T>(
  parts: Record<string, unknown>,
  value: T,
  ttlSeconds = RedisTTL.aiFortune,
): Promise<void> {
  const { kvSet } = await import("./client");
  const key = RedisKeys.cache.aiFortune(aiFortuneCacheKey(parts));
  await kvSet(key, JSON.stringify(value), ttlSeconds);
}

export async function aiFortuneCacheGetOrSet<T>(
  parts: Record<string, unknown>,
  loader: () => Promise<T>,
  ttlSeconds = RedisTTL.aiFortune,
): Promise<T> {
  const key = RedisKeys.cache.aiFortune(aiFortuneCacheKey(parts));
  return cacheGetOrSet(key, ttlSeconds, loader);
}
