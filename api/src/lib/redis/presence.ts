import { kvDel, kvGet, kvSet, isRedisReady, getRedisClient } from "./client";
import { memoryKv } from "./memoryKv";
import { RedisKeys, RedisTTL } from "./keys";
import { redisPublish } from "./pubsub";

export type PresenceUser = {
  userId: string;
  displayName?: string;
  roomId?: string;
  lastSeen: number;
};

function serializeUser(user: PresenceUser): string {
  return JSON.stringify(user);
}

function parseUser(raw: string | null): PresenceUser | null {
  if (!raw) return null;
  try {
    return JSON.parse(raw) as PresenceUser;
  } catch {
    return null;
  }
}

/** Kullanıcı çevrimiçi — giriş veya heartbeat */
export async function presenceSetOnline(
  userId: string,
  meta?: { displayName?: string; roomId?: string },
): Promise<void> {
  const now = Date.now();
  const payload: PresenceUser = {
    userId,
    displayName: meta?.displayName,
    roomId: meta?.roomId,
    lastSeen: now,
  };
  await kvSet(RedisKeys.presence.user(userId), serializeUser(payload), RedisTTL.presenceHeartbeat * 3);
  if (isRedisReady() && getRedisClient()) {
    try {
      await getRedisClient()!.sAdd(RedisKeys.presence.onlineUsers, userId);
    } catch {
      /* fallback */
    }
  } else {
    memoryKv.sadd(RedisKeys.presence.onlineUsers, userId);
  }
  if (meta?.roomId) {
    await presenceJoinRoom(meta.roomId, userId, payload);
  }
}

/** Heartbeat — 20 sn TTL yenileme */
export async function presenceHeartbeat(
  userId: string,
  roomId?: string,
): Promise<void> {
  const existing = parseUser(await kvGet(RedisKeys.presence.user(userId)));
  const payload: PresenceUser = {
    userId,
    displayName: existing?.displayName,
    roomId: roomId ?? existing?.roomId,
    lastSeen: Date.now(),
  };
  await kvSet(
    RedisKeys.presence.user(userId),
    serializeUser(payload),
    RedisTTL.presenceHeartbeat * 3,
  );
  if (roomId) {
    const roomKey = RedisKeys.presence.roomUsers(roomId);
    if (isRedisReady() && getRedisClient()) {
      try {
        await getRedisClient()!.hSet(roomKey, userId, serializeUser(payload));
        await getRedisClient()!.expire(roomKey, RedisTTL.presenceHeartbeat * 3);
      } catch {
        memoryKv.hset(roomKey, userId, serializeUser(payload));
      }
    } else {
      memoryKv.hset(roomKey, userId, serializeUser(payload));
    }
  }
}

export async function presenceJoinRoom(
  roomId: string,
  userId: string,
  user?: PresenceUser,
): Promise<void> {
  const row =
    user ??
    parseUser(await kvGet(RedisKeys.presence.user(userId))) ?? {
      userId,
      lastSeen: Date.now(),
    };
  row.roomId = roomId;
  row.lastSeen = Date.now();
  const roomKey = RedisKeys.presence.roomUsers(roomId);
  const serialized = serializeUser(row);
  if (isRedisReady() && getRedisClient()) {
    try {
      await getRedisClient()!.hSet(roomKey, userId, serialized);
      await getRedisClient()!.expire(roomKey, RedisTTL.presenceHeartbeat * 3);
    } catch {
      memoryKv.hset(roomKey, userId, serialized);
    }
  } else {
    memoryKv.hset(roomKey, userId, serialized);
  }
  await redisPublish(RedisKeys.pubsub.room, { type: "join", roomId, userId });
}

export async function presenceLeaveRoom(roomId: string, userId: string): Promise<void> {
  const roomKey = RedisKeys.presence.roomUsers(roomId);
  if (isRedisReady() && getRedisClient()) {
    try {
      await getRedisClient()!.hDel(roomKey, userId);
    } catch {
      memoryKv.hdel(roomKey, userId);
    }
  } else {
    memoryKv.hdel(roomKey, userId);
  }
  await redisPublish(RedisKeys.pubsub.room, { type: "leave", roomId, userId });
}

export async function presenceSetOffline(userId: string): Promise<void> {
  const user = parseUser(await kvGet(RedisKeys.presence.user(userId)));
  if (user?.roomId) await presenceLeaveRoom(user.roomId, userId);
  await kvDel(RedisKeys.presence.user(userId));
  if (isRedisReady() && getRedisClient()) {
    try {
      await getRedisClient()!.sRem(RedisKeys.presence.onlineUsers, userId);
    } catch {
      memoryKv.srem(RedisKeys.presence.onlineUsers, userId);
    }
  } else {
    memoryKv.srem(RedisKeys.presence.onlineUsers, userId);
  }
}

export async function presenceListRoomUsers(roomId: string): Promise<PresenceUser[]> {
  const roomKey = RedisKeys.presence.roomUsers(roomId);
  let map: Record<string, string> = {};
  if (isRedisReady() && getRedisClient()) {
    try {
      map = await getRedisClient()!.hGetAll(roomKey);
    } catch {
      map = memoryKv.hgetall(roomKey);
    }
  } else {
    map = memoryKv.hgetall(roomKey);
  }
  const now = Date.now();
  const ttlMs = RedisTTL.presenceHeartbeat * 3 * 1000;
  const users: PresenceUser[] = [];
  for (const [uid, raw] of Object.entries(map)) {
    const row = parseUser(raw);
    if (!row) continue;
    if (now - row.lastSeen > ttlMs) {
      await presenceLeaveRoom(roomId, uid);
      continue;
    }
    users.push(row);
  }
  return users;
}

export async function presenceOnlineCount(): Promise<number> {
  if (isRedisReady() && getRedisClient()) {
    try {
      return await getRedisClient()!.sCard(RedisKeys.presence.onlineUsers);
    } catch {
      return memoryKv.smembers(RedisKeys.presence.onlineUsers).length;
    }
  }
  return memoryKv.smembers(RedisKeys.presence.onlineUsers).length;
}
