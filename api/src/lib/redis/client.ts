import { createClient, type RedisClientType } from "redis";
import { memoryKv } from "./memoryKv";

let client: RedisClientType | null = null;
let subscriber: RedisClientType | null = null;
let redisReady = false;
let connecting = false;

const INSTANCE_ID =
  process.env.REDIS_INSTANCE_ID ??
  `api-${process.pid}-${Math.random().toString(36).slice(2, 8)}`;

export function getRedisInstanceId() {
  return INSTANCE_ID;
}

export function isRedisReady() {
  return redisReady && client?.isOpen === true;
}

export function getRedisClient() {
  return isRedisReady() ? client : null;
}

export function getRedisSubscriber() {
  return isRedisReady() ? subscriber : null;
}

export async function initRedis(): Promise<void> {
  const url = process.env.REDIS_URL?.trim();
  if (!url) {
    console.warn("[redis] REDIS_URL tanımlı değil — bellek/PostgreSQL modu");
    return;
  }
  if (connecting || isRedisReady()) return;
  connecting = true;
  try {
    client = createClient({
      url,
      socket: {
        reconnectStrategy: (retries) => {
          if (retries > 50) return new Error("Redis yeniden bağlanma limiti");
          return Math.min(retries * 200, 5000);
        },
      },
    });
    subscriber = client.duplicate();

    client.on("error", (err) => {
      redisReady = false;
      console.warn("[redis] istemci hatası:", err.message);
    });
    client.on("ready", () => {
      redisReady = true;
      console.log("[redis] bağlantı hazır");
    });
    client.on("end", () => {
      redisReady = false;
      console.warn("[redis] bağlantı kapandı — fallback aktif");
    });

    await client.connect();
    await subscriber.connect();
    redisReady = true;
    console.log(`[redis] bağlandı (${INSTANCE_ID})`);
  } catch (err) {
    redisReady = false;
    const msg = err instanceof Error ? err.message : String(err);
    console.warn("[redis] bağlanılamadı, fallback:", msg);
  } finally {
    connecting = false;
  }
}

export async function shutdownRedis(): Promise<void> {
  redisReady = false;
  await subscriber?.quit().catch(() => undefined);
  await client?.quit().catch(() => undefined);
  subscriber = null;
  client = null;
}

/** Redis veya bellek — GET */
export async function kvGet(key: string): Promise<string | null> {
  if (isRedisReady() && client) {
    try {
      return await client.get(key);
    } catch {
      redisReady = false;
    }
  }
  return memoryKv.get(key);
}

/** Redis veya bellek — SET + EX */
export async function kvSet(
  key: string,
  value: string,
  ttlSeconds?: number,
): Promise<void> {
  if (isRedisReady() && client) {
    try {
      if (ttlSeconds) await client.set(key, value, { EX: ttlSeconds });
      else await client.set(key, value);
      return;
    } catch {
      redisReady = false;
    }
  }
  memoryKv.set(key, value, ttlSeconds);
}

export async function kvDel(key: string): Promise<void> {
  if (isRedisReady() && client) {
    try {
      await client.del(key);
      return;
    } catch {
      redisReady = false;
    }
  }
  memoryKv.del(key);
}

export async function kvIncr(key: string, ttlSeconds?: number): Promise<number> {
  if (isRedisReady() && client) {
    try {
      const n = await client.incr(key);
      if (ttlSeconds) await client.expire(key, ttlSeconds);
      return n;
    } catch {
      redisReady = false;
    }
  }
  const n = memoryKv.incr(key);
  if (ttlSeconds) memoryKv.expire(key, ttlSeconds);
  return n;
}

export async function kvExpire(key: string, ttlSeconds: number): Promise<void> {
  if (isRedisReady() && client) {
    try {
      await client.expire(key, ttlSeconds);
      return;
    } catch {
      redisReady = false;
    }
  }
  memoryKv.expire(key, ttlSeconds);
}

export { memoryKv };
