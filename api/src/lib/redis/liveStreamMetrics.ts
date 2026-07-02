import { getRedisClient, isRedisReady, kvGet, kvSet } from "./client";
import { memoryKv } from "./memoryKv";
import { RedisKeys } from "./keys";

export type LiveMetricField = "viewers" | "likes" | "comments" | "gifts";

function metricKey(streamId: string, field: LiveMetricField) {
  switch (field) {
    case "viewers":
      return RedisKeys.live.viewers(streamId);
    case "likes":
      return RedisKeys.live.likes(streamId);
    case "comments":
      return RedisKeys.live.comments(streamId);
    case "gifts":
      return RedisKeys.live.gifts(streamId);
  }
}

export async function liveMetricIncr(
  streamId: string,
  field: LiveMetricField,
  delta = 1,
): Promise<number> {
  const key = metricKey(streamId, field);
  if (isRedisReady() && getRedisClient()) {
    try {
      return await getRedisClient()!.incrBy(key, delta);
    } catch {
      /* fallback */
    }
  }
  const current = Number(memoryKv.get(key) ?? "0");
  const next = current + delta;
  memoryKv.set(key, String(next));
  return next;
}

export async function liveMetricSet(
  streamId: string,
  field: LiveMetricField,
  value: number,
): Promise<void> {
  const key = metricKey(streamId, field);
  if (isRedisReady() && getRedisClient()) {
    try {
      await getRedisClient()!.set(key, String(value));
      return;
    } catch {
      /* fallback */
    }
  }
  memoryKv.set(key, String(value));
}

export async function liveMetricGet(
  streamId: string,
  field: LiveMetricField,
): Promise<number> {
  const key = metricKey(streamId, field);
  const raw = await kvGet(key);
  return Number(raw ?? "0");
}

export async function liveMetricSnapshot(streamId: string) {
  const [viewers, likes, comments, gifts] = await Promise.all([
    liveMetricGet(streamId, "viewers"),
    liveMetricGet(streamId, "likes"),
    liveMetricGet(streamId, "comments"),
    liveMetricGet(streamId, "gifts"),
  ]);
  return { viewers, likes, comments, gifts };
}

/** Periyodik PG senkronu için dirty işareti */
export async function liveMarkDirty(streamId: string): Promise<void> {
  await kvSet(`live:${streamId}:dirty`, "1", 300);
}

export async function livePopDirtyStreams(): Promise<string[]> {
  // Basit tarama — üretimde SCAN kullanılabilir
  return [];
}
