import { getRedisClient, isRedisReady } from "./client";
import { memoryKv } from "./memoryKv";
import { RedisKeys } from "./keys";
import { redisPublish } from "./pubsub";

export async function musicQueuePush(
  roomId: string,
  item: Record<string, unknown>,
  position: "left" | "right" = "right",
): Promise<number> {
  const key = RedisKeys.music.queue(roomId);
  const payload = JSON.stringify(item);
  if (isRedisReady() && getRedisClient()) {
    try {
      const len =
        position === "left"
          ? await getRedisClient()!.lPush(key, payload)
          : await getRedisClient()!.rPush(key, payload);
      await redisPublish(RedisKeys.pubsub.music, { type: "enqueue", roomId, item });
      return len;
    } catch {
      /* fallback */
    }
  }
  const len =
    position === "left"
      ? memoryKv.lpush(key, payload)
      : memoryKv.rpush(key, payload);
  await redisPublish(RedisKeys.pubsub.music, { type: "enqueue", roomId, item });
  return len;
}

export async function musicQueuePop(roomId: string): Promise<Record<string, unknown> | null> {
  const key = RedisKeys.music.queue(roomId);
  let raw: string | null = null;
  if (isRedisReady() && getRedisClient()) {
    try {
      raw = await getRedisClient()!.lPop(key);
    } catch {
      raw = memoryKv.lpop(key);
    }
  } else {
    raw = memoryKv.lpop(key);
  }
  if (!raw) return null;
  try {
    return JSON.parse(raw) as Record<string, unknown>;
  } catch {
    return null;
  }
}

export async function musicQueueList(roomId: string): Promise<Record<string, unknown>[]> {
  const key = RedisKeys.music.queue(roomId);
  let items: string[] = [];
  if (isRedisReady() && getRedisClient()) {
    try {
      items = await getRedisClient()!.lRange(key, 0, -1);
    } catch {
      items = memoryKv.lrange(key, 0, -1);
    }
  } else {
    items = memoryKv.lrange(key, 0, -1);
  }
  return items
    .map((raw) => {
      try {
        return JSON.parse(raw) as Record<string, unknown>;
      } catch {
        return null;
      }
    })
    .filter((x): x is Record<string, unknown> => x != null);
}

/** Sonraki parça — BLPOP benzeri (kısa timeout ile) */
export async function musicQueueBlockingPop(
  roomId: string,
  timeoutSeconds = 1,
): Promise<Record<string, unknown> | null> {
  const key = RedisKeys.music.queue(roomId);
  if (isRedisReady() && getRedisClient()) {
    try {
      const res = await getRedisClient()!.blPop(key, timeoutSeconds);
      if (!res) return null;
      return JSON.parse(res.element) as Record<string, unknown>;
    } catch {
      return musicQueuePop(roomId);
    }
  }
  return musicQueuePop(roomId);
}

export async function musicQueueRemoveById(roomId: string, itemId: string): Promise<void> {
  const list = await musicQueueList(roomId);
  const key = RedisKeys.music.queue(roomId);
  const filtered = list.filter((i) => String(i.id ?? "") !== itemId);
  if (isRedisReady() && getRedisClient()) {
    try {
      await getRedisClient()!.del(key);
      if (filtered.length > 0) {
        await getRedisClient()!.rPush(
          key,
          filtered.map((i) => JSON.stringify(i)),
        );
      }
      return;
    } catch {
      /* fallback */
    }
  }
  memoryKv.del(key);
  for (const item of filtered) {
    memoryKv.rpush(key, JSON.stringify(item));
  }
}
