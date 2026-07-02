import { kvDel, kvGet, kvSet } from "./client";
import { RedisKeys, RedisTTL } from "./keys";

export type ActiveSession = {
  userId: string;
  deviceId?: string;
  platform?: string;
  lastActiveAt: number;
  ip?: string;
};

export async function sessionSetActive(
  userId: string,
  meta?: Omit<ActiveSession, "userId" | "lastActiveAt">,
): Promise<void> {
  const payload: ActiveSession = {
    userId,
    ...meta,
    lastActiveAt: Date.now(),
  };
  await kvSet(
    RedisKeys.session.active(userId),
    JSON.stringify(payload),
    RedisTTL.session,
  );
}

export async function sessionTouch(userId: string): Promise<void> {
  const raw = await kvGet(RedisKeys.session.active(userId));
  if (!raw) {
    await sessionSetActive(userId);
    return;
  }
  try {
    const parsed = JSON.parse(raw) as ActiveSession;
    parsed.lastActiveAt = Date.now();
    await kvSet(
      RedisKeys.session.active(userId),
      JSON.stringify(parsed),
      RedisTTL.session,
    );
  } catch {
    await sessionSetActive(userId);
  }
}

export async function sessionClear(userId: string): Promise<void> {
  await kvDel(RedisKeys.session.active(userId));
}

export async function sessionGet(userId: string): Promise<ActiveSession | null> {
  const raw = await kvGet(RedisKeys.session.active(userId));
  if (!raw) return null;
  try {
    return JSON.parse(raw) as ActiveSession;
  } catch {
    return null;
  }
}
