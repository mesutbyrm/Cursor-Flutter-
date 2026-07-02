import { getRedisClient, isRedisReady } from "./client";
import { memoryKv } from "./memoryKv";
import { RedisKeys } from "./keys";
import { redisPublish } from "./pubsub";

export type VoiceRole = "speaker" | "admin" | "listener";

function roleKey(roomId: string, role: VoiceRole) {
  switch (role) {
    case "speaker":
      return RedisKeys.voice.speakers(roomId);
    case "admin":
      return RedisKeys.voice.admins(roomId);
    case "listener":
      return RedisKeys.voice.listeners(roomId);
  }
}

export async function voiceRoomSetMeta(
  roomId: string,
  meta: Record<string, string>,
): Promise<void> {
  const key = RedisKeys.voice.room(roomId);
  if (isRedisReady() && getRedisClient()) {
    try {
      await getRedisClient()!.hSet(key, meta);
      return;
    } catch {
      /* fallback */
    }
  }
  for (const [field, value] of Object.entries(meta)) {
    memoryKv.hset(key, field, value);
  }
}

export async function voiceRoomAddUser(
  roomId: string,
  userId: string,
  role: VoiceRole,
  profile?: Record<string, string>,
): Promise<void> {
  const key = roleKey(roomId, role);
  const payload = JSON.stringify({ userId, ...profile, joinedAt: Date.now() });
  if (isRedisReady() && getRedisClient()) {
    try {
      await getRedisClient()!.hSet(key, userId, payload);
    } catch {
      memoryKv.hset(key, userId, payload);
    }
  } else {
    memoryKv.hset(key, userId, payload);
  }
  await redisPublish(RedisKeys.pubsub.room, { type: "voice_join", roomId, userId, role });
}

export async function voiceRoomRemoveUser(
  roomId: string,
  userId: string,
): Promise<void> {
  for (const role of ["speaker", "admin", "listener"] as VoiceRole[]) {
    const key = roleKey(roomId, role);
    if (isRedisReady() && getRedisClient()) {
      try {
        await getRedisClient()!.hDel(key, userId);
      } catch {
        memoryKv.hdel(key, userId);
      }
    } else {
      memoryKv.hdel(key, userId);
    }
  }
  await redisPublish(RedisKeys.pubsub.room, { type: "voice_leave", roomId, userId });
}

export async function voiceRoomListRole(
  roomId: string,
  role: VoiceRole,
): Promise<Record<string, unknown>[]> {
  const key = roleKey(roomId, role);
  let map: Record<string, string> = {};
  if (isRedisReady() && getRedisClient()) {
    try {
      map = await getRedisClient()!.hGetAll(key);
    } catch {
      map = memoryKv.hgetall(key);
    }
  } else {
    map = memoryKv.hgetall(key);
  }
  return Object.values(map).map((raw) => {
    try {
      return JSON.parse(raw) as Record<string, unknown>;
    } catch {
      return { raw };
    }
  });
}

export async function voiceRoomSnapshot(roomId: string) {
  const [speakers, admins, listeners] = await Promise.all([
    voiceRoomListRole(roomId, "speaker"),
    voiceRoomListRole(roomId, "admin"),
    voiceRoomListRole(roomId, "listener"),
  ]);
  return { speakers, admins, listeners };
}
