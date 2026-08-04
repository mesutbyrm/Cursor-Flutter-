import { randomUUID } from "node:crypto";
import type { User } from "@prisma/client";
import { prisma } from "./prisma";
import { logMusicAction } from "./musicActionLog";
import { emitSongSse } from "./songQueueSse";
import { musicQueuePush } from "./redis/musicQueue";
import {
  searchMusicViaYoutubeApi,
  formatIso8601Duration,
} from "./youtubeMusicSearch";
import {
  canControlRoomMusic,
  getChatRoom,
  getRoomMusicSettings,
  getRoomType,
  listMusicQueue,
  type ChatRoomRow,
  type MusicQueueItem,
} from "./chatRoomStore";
import { getVoiceRoomSettings } from "./voiceRoomSettings";
import { applyMusicPayout } from "./voiceRoomRevenue";
import { logJetonDebit } from "./musicQueueService";

export type SongQueueRow = {
  id: string;
  roomId: string;
  userId: string;
  username: string | null;
  videoId: string;
  title: string;
  thumbnail: string | null;
  duration: string | null;
  channel: string | null;
  status: "queued" | "playing" | "played" | "removed";
  position: number;
  createdAt: Date;
};

export type CurrentSongSnapshot = {
  queueId: string | null;
  videoId: string | null;
  title: string | null;
  thumbnail: string | null;
  duration: number | null;
  channel: string | null;
  owner: { id: string; name: string } | null;
  startedAt: number | null;
  paused: boolean;
  pausedAt: number | null;
  elapsedMs: number;
  serverTime: number;
};

type RoomRuntime = {
  queue: SongQueueRow[];
  current: Omit<CurrentSongSnapshot, "serverTime">;
  finishTimer: ReturnType<typeof setTimeout> | null;
};

const runtimeByRoom = new Map<string, RoomRuntime>();

function roomKey(roomId: string) {
  return roomId.trim();
}

function emptyCurrent(): Omit<CurrentSongSnapshot, "serverTime"> {
  return {
    queueId: null,
    videoId: null,
    title: null,
    thumbnail: null,
    duration: null,
    channel: null,
    owner: null,
    startedAt: null,
    paused: false,
    pausedAt: null,
    elapsedMs: 0,
  };
}

function runtime(roomId: string): RoomRuntime {
  const key = roomKey(roomId);
  let rt = runtimeByRoom.get(key);
  if (!rt) {
    rt = { queue: [], current: emptyCurrent(), finishTimer: null };
    runtimeByRoom.set(key, rt);
  }
  return rt;
}

function parseDurationSec(dur: string | null | undefined): number | null {
  if (!dur?.trim()) return null;
  const parts = dur.trim().split(":").map((p) => Number(p.trim()));
  if (parts.some((n) => Number.isNaN(n))) return null;
  if (parts.length === 2) return parts[0]! * 60 + parts[1]!;
  if (parts.length === 3) return parts[0]! * 3600 + parts[1]! * 60 + parts[2]!;
  return null;
}

function computeElapsedMs(rt: RoomRuntime, now = Date.now()): number {
  const c = rt.current;
  if (!c.videoId) return 0;
  if (c.paused) return c.elapsedMs;
  if (c.startedAt == null) return c.elapsedMs;
  return c.elapsedMs + Math.max(0, now - c.startedAt);
}

function toPublicCurrent(rt: RoomRuntime): CurrentSongSnapshot {
  const now = Date.now();
  return {
    ...rt.current,
    elapsedMs: computeElapsedMs(rt, now),
    serverTime: now,
  };
}

function toPublicQueueItem(row: SongQueueRow) {
  return {
    queueId: row.id,
    id: row.id,
    videoId: row.videoId,
    title: row.title,
    thumbnail: row.thumbnail,
    duration: row.duration,
    channel: row.channel,
    owner: row.username
      ? { id: row.userId, name: row.username }
      : { id: row.userId, name: "Kullanıcı" },
    position: row.position,
    createdAt: row.createdAt.toISOString(),
  };
}

function clearFinishTimer(rt: RoomRuntime) {
  if (rt.finishTimer) {
    clearTimeout(rt.finishTimer);
    rt.finishTimer = null;
  }
}

function scheduleAutoFinish(roomId: string, rt: RoomRuntime) {
  clearFinishTimer(rt);
  const durSec = rt.current.duration;
  if (!durSec || durSec <= 0 || rt.current.paused) return;
  const elapsed = computeElapsedMs(rt);
  const remaining = Math.max(1000, durSec * 1000 - elapsed + 500);
  rt.finishTimer = setTimeout(() => {
    void finishCurrentSong(roomId, { auto: true });
  }, remaining);
}

async function persistCurrent(roomId: string, rt: RoomRuntime) {
  const key = roomKey(roomId);
  const c = rt.current;
  try {
    await prisma.roomCurrentSong.upsert({
      where: { roomId: key },
      create: {
        roomId: key,
        queueId: c.queueId,
        videoId: c.videoId,
        title: c.title,
        thumbnail: c.thumbnail,
        durationSec: c.duration,
        channel: c.channel,
        ownerId: c.owner?.id ?? null,
        ownerName: c.owner?.name ?? null,
        startedAt: c.startedAt ? new Date(c.startedAt) : null,
        pausedAt: c.pausedAt ? new Date(c.pausedAt) : null,
        paused: c.paused,
        elapsedMs: computeElapsedMs(rt),
      },
      update: {
        queueId: c.queueId,
        videoId: c.videoId,
        title: c.title,
        thumbnail: c.thumbnail,
        durationSec: c.duration,
        channel: c.channel,
        ownerId: c.owner?.id ?? null,
        ownerName: c.owner?.name ?? null,
        startedAt: c.startedAt ? new Date(c.startedAt) : null,
        pausedAt: c.pausedAt ? new Date(c.pausedAt) : null,
        paused: c.paused,
        elapsedMs: computeElapsedMs(rt),
      },
    });
  } catch {
    /* bellek yeterli */
  }
}

async function writeHistory(
  roomId: string,
  row: SongQueueRow,
  opts: { skipped?: boolean; durationSec?: number | null },
) {
  const key = roomKey(roomId);
  try {
    const existing = await prisma.roomSongHistory.findFirst({
      where: { roomId: key, videoId: row.videoId, requestedById: row.userId },
      orderBy: { playedAt: "desc" },
    });
    if (existing) {
      await prisma.roomSongHistory.update({
        where: { id: existing.id },
        data: {
          playCount: existing.playCount + 1,
          playedAt: new Date(),
          finishedAt: new Date(),
          skipped: opts.skipped ?? false,
          durationSec: opts.durationSec ?? existing.durationSec,
        },
      });
    } else {
      await prisma.roomSongHistory.create({
        data: {
          roomId: key,
          queueId: row.id,
          videoId: row.videoId,
          title: row.title,
          thumbnail: row.thumbnail,
          durationSec: opts.durationSec ?? parseDurationSec(row.duration),
          channel: row.channel,
          requestedById: row.userId,
          requestedBy: row.username,
          finishedAt: new Date(),
          skipped: opts.skipped ?? false,
        },
      });
    }
  } catch {
    /* */
  }
}

function emitQueue(roomId: string, type: Parameters<typeof emitSongSse>[1]["type"]) {
  const rt = runtime(roomId);
  emitSongSse(roomId, {
    type,
    roomId: roomKey(roomId),
    currentSong: rt.current.videoId ? toPublicCurrent(rt) : null,
    queue: rt.queue
      .filter((q) => q.status === "queued")
      .map(toPublicQueueItem),
    elapsed: computeElapsedMs(rt) / 1000,
    paused: rt.current.paused,
  });
}

async function loadRoomFromDb(roomId: string) {
  const key = roomKey(roomId);
  const rt = runtime(roomId);
  try {
    const rows = await prisma.roomSongQueue.findMany({
      where: { roomId: key, status: { in: ["queued", "playing"] } },
      orderBy: [{ position: "asc" }, { createdAt: "asc" }],
    });
    if (rows.length > 0) {
      rt.queue = rows.map((r) => ({
        id: r.id,
        roomId: r.roomId,
        userId: r.userId,
        username: r.username,
        videoId: r.videoId,
        title: r.title,
        thumbnail: r.thumbnail,
        duration: r.duration,
        channel: r.channel,
        status: r.status as SongQueueRow["status"],
        position: r.position,
        createdAt: r.createdAt,
      }));
    }
    const cur = await prisma.roomCurrentSong.findUnique({ where: { roomId: key } });
    if (cur?.videoId) {
      rt.current = {
        queueId: cur.queueId,
        videoId: cur.videoId,
        title: cur.title,
        thumbnail: cur.thumbnail,
        duration: cur.durationSec,
        channel: cur.channel,
        owner: cur.ownerId
          ? { id: cur.ownerId, name: cur.ownerName ?? "Kullanıcı" }
          : null,
        startedAt: cur.startedAt?.getTime() ?? null,
        paused: cur.paused,
        pausedAt: cur.pausedAt?.getTime() ?? null,
        elapsedMs: cur.elapsedMs,
      };
      scheduleAutoFinish(roomId, rt);
    }
  } catch {
    /* */
  }
}

export async function songQueueEnsureLoaded(roomId: string) {
  const rt = runtime(roomId);
  if (rt.queue.length === 0 && !rt.current.videoId) {
    await loadRoomFromDb(roomId);
  }
}

export async function songQueueSearch(query: string, limit = 10) {
  const hits = await searchMusicViaYoutubeApi(query, { maxResults: limit });
  return hits.map((h) => ({
    videoId: h.videoId,
    title: h.title,
    thumbnail: h.thumbnail,
    duration: h.duration,
    channel: h.channelTitle,
  }));
}

export async function songQueueGetCurrent(roomId: string) {
  await songQueueEnsureLoaded(roomId);
  const rt = runtime(roomId);
  return toPublicCurrent(rt);
}

export async function songQueueGetQueue(roomId: string) {
  await songQueueEnsureLoaded(roomId);
  const rt = runtime(roomId);
  return {
    queue: rt.queue
      .filter((q) => q.status === "queued" || q.status === "playing")
      .map(toPublicQueueItem),
    currentSong: rt.current.videoId ? toPublicCurrent(rt) : null,
    serverTime: Date.now(),
  };
}

function canModerate(user: User, room: ChatRoomRow, nowPlaying: MusicQueueItem | null) {
  const priv = canControlRoomMusic(user, room, nowPlaying);
  const r = (user.role ?? "").toLowerCase();
  return (
    priv ||
    r === "moderator" ||
    r === "mod" ||
    r === "admin" ||
    r === "super_admin"
  );
}

export async function songQueueRequest(
  roomId: string,
  user: User,
  input: {
    videoId?: string;
    title?: string;
    thumbnail?: string | null;
    duration?: string | null;
    channel?: string | null;
    youtubeUrl?: string;
    priority?: boolean;
  },
) {
  const room = getChatRoom(roomId);
  if (!room) return { ok: false as const, error: "Oda bulunamadı" };
  const settings = getRoomMusicSettings(roomId);
  if (!settings.musicEnabled) {
    return { ok: false as const, error: "Müzik sistemi kapalı" };
  }

  await songQueueEnsureLoaded(roomId);
  const rt = runtime(roomId);
  const queuedCount = rt.queue.filter((q) => q.status === "queued").length;
  const hasPlaying = Boolean(rt.current.videoId);
  if (queuedCount + (hasPlaying ? 1 : 0) >= settings.maxQueueLength) {
    return { ok: false as const, error: `Kuyruk dolu (maks. ${settings.maxQueueLength})` };
  }

  let videoId =
    input.videoId?.trim() ||
    (input.youtubeUrl ? extractYoutubeId(input.youtubeUrl) : null);
  if (!videoId) return { ok: false as const, error: "videoId gerekli" };

  const platformSettings = await getVoiceRoomSettings();
  const roomType = getRoomType(room);
  const isVip = roomType === "VIP";
  const cost = isVip ? 0 : settings.musicRequestCost || platformSettings.musicRequestCost;

  const dbUser = await prisma.user.findUnique({ where: { id: user.id } });
  if (!dbUser) return { ok: false as const, error: "Oturum gerekli" };
  if (cost > 0 && (dbUser.coins ?? 0) < cost) {
    return {
      ok: false as const,
      error: "Yetersiz jeton",
      code: "INSUFFICIENT_JETON" as const,
    };
  }

  let newBalance = dbUser.coins ?? 0;
  if (cost > 0) {
    const updated = await prisma.user.update({
      where: { id: user.id },
      data: { coins: { decrement: cost } },
    });
    newBalance = updated.coins;
    await logJetonDebit({
      roomId,
      user,
      amount: cost,
      balanceAfter: newBalance,
      songName: input.title ?? "Şarkı",
    });
    await applyMusicPayout({
      roomId: roomKey(roomId),
      roomType,
      requesterId: user.id,
      ownerId: room.ownerId ?? null,
      totalCost: cost,
      songName: input.title ?? "Şarkı",
      settings: platformSettings,
    });
  }

  const title = (input.title ?? "Şarkı").trim() || "Şarkı";
  const row: SongQueueRow = {
    id: randomUUID(),
    roomId: roomKey(roomId),
    userId: user.id,
    username: user.username ?? user.displayName ?? null,
    videoId,
    title,
    thumbnail: input.thumbnail ?? null,
    duration: input.duration ?? null,
    channel: input.channel ?? null,
    status: "queued",
    position: rt.queue.length,
    createdAt: new Date(),
  };

  if (input.priority && rt.current.videoId) {
    const insertAt = rt.queue.findIndex((q) => q.status === "queued");
    const pos = insertAt >= 0 ? insertAt : rt.queue.length;
    rt.queue.splice(pos, 0, row);
    rt.queue.forEach((q, i) => {
      q.position = i;
    });
  } else {
    rt.queue.push(row);
    row.position = rt.queue.length - 1;
  }

  try {
    await prisma.roomSongQueue.create({
      data: {
        id: row.id,
        roomId: row.roomId,
        userId: row.userId,
        username: row.username,
        videoId: row.videoId,
        title: row.title,
        thumbnail: row.thumbnail,
        duration: row.duration,
        channel: row.channel,
        status: row.status,
        position: row.position,
        createdAt: row.createdAt,
      },
    });
  } catch {
    /* */
  }

  void musicQueuePush(row.roomId, toPublicQueueItem(row) as Record<string, unknown>);

  await logMusicAction({
    roomId: roomKey(roomId),
    userId: user.id,
    username: row.username,
    action: "Queue Add",
    metadata: { videoId, title },
  });

  if (!rt.current.videoId) {
    await startNextSong(roomId);
  } else {
    emitQueue(roomId, "queue_updated");
  }

  return {
    ok: true as const,
    item: toPublicQueueItem(row),
    queue: rt.queue.filter((q) => q.status !== "removed").map(toPublicQueueItem),
    newBalance,
    cost,
  };
}

async function startNextSong(roomId: string) {
  const rt = runtime(roomId);
  clearFinishTimer(rt);
  const next = rt.queue.find((q) => q.status === "queued");
  if (!next) {
    rt.current = emptyCurrent();
    await persistCurrent(roomId, rt);
    emitQueue(roomId, "song_finished");
    return null;
  }

  next.status = "playing";
  const durSec = parseDurationSec(next.duration);
  const now = Date.now();
  rt.current = {
    queueId: next.id,
    videoId: next.videoId,
    title: next.title,
    thumbnail: next.thumbnail,
    duration: durSec,
    channel: next.channel,
    owner: next.username
      ? { id: next.userId, name: next.username }
      : { id: next.userId, name: "Kullanıcı" },
    startedAt: now,
    paused: false,
    pausedAt: null,
    elapsedMs: 0,
  };

  try {
    await prisma.roomSongQueue.update({
      where: { id: next.id },
      data: { status: "playing" },
    });
  } catch {
    /* */
  }

  await persistCurrent(roomId, rt);
  scheduleAutoFinish(roomId, rt);

  await logMusicAction({
    roomId: roomKey(roomId),
    userId: next.userId,
    username: next.username,
    action: "Song started",
    metadata: { videoId: next.videoId, title: next.title },
  });

  emitSongSse(roomId, {
    type: "song_started",
    roomId: roomKey(roomId),
    currentSong: toPublicCurrent(rt),
    queue: rt.queue.filter((q) => q.status === "queued").map(toPublicQueueItem),
    elapsed: 0,
    paused: false,
  });

  return rt.current;
}

export async function finishCurrentSong(
  roomId: string,
  opts?: { auto?: boolean; skipped?: boolean },
) {
  const rt = runtime(roomId);
  clearFinishTimer(rt);
  const playing = rt.queue.find((q) => q.status === "playing");
  if (playing) {
    playing.status = "played";
    await writeHistory(roomId, playing, {
      skipped: opts?.skipped ?? false,
      durationSec: parseDurationSec(playing.duration),
    });
    try {
      await prisma.roomSongQueue.update({
        where: { id: playing.id },
        data: { status: "played" },
      });
    } catch {
      /* */
    }
    rt.queue = rt.queue.filter((q) => q.status !== "played");
  }

  rt.current = emptyCurrent();
  await persistCurrent(roomId, rt);

  await logMusicAction({
    roomId: roomKey(roomId),
    userId: playing?.userId,
    username: playing?.username,
    action: opts?.skipped ? "Skip" : "Song finished",
    metadata: playing ? { videoId: playing.videoId, title: playing.title } : {},
  });

  emitSongSse(roomId, {
    type: opts?.skipped ? "song_finished" : "song_finished",
    roomId: roomKey(roomId),
    currentSong: null,
    queue: rt.queue.filter((q) => q.status === "queued").map(toPublicQueueItem),
    elapsed: 0,
    paused: false,
  });

  await startNextSong(roomId);
}

export async function songQueueSkip(roomId: string, user: User) {
  const room = getChatRoom(roomId);
  if (!room) return { ok: false as const, error: "Oda bulunamadı" };
  await songQueueEnsureLoaded(roomId);
  const legacyNow = listMusicQueue(roomId)[0] ?? null;
  if (!canModerate(user, room, legacyNow)) {
    return { ok: false as const, error: "Yetki yok" };
  }
  await finishCurrentSong(roomId, { skipped: true });
  return { ok: true as const, current: await songQueueGetCurrent(roomId) };
}

export async function songQueuePause(roomId: string, user: User) {
  const room = getChatRoom(roomId);
  if (!room) return { ok: false as const, error: "Oda bulunamadı" };
  await songQueueEnsureLoaded(roomId);
  const rt = runtime(roomId);
  if (!rt.current.videoId) return { ok: false as const, error: "Çalan şarkı yok" };
  const legacyNow = listMusicQueue(roomId)[0] ?? null;
  if (!canModerate(user, room, legacyNow)) {
    return { ok: false as const, error: "Yetki yok" };
  }
  if (rt.current.paused) return { ok: true as const, current: toPublicCurrent(rt) };

  const now = Date.now();
  rt.current.elapsedMs = computeElapsedMs(rt, now);
  rt.current.paused = true;
  rt.current.pausedAt = now;
  rt.current.startedAt = null;
  clearFinishTimer(rt);
  await persistCurrent(roomId, rt);

  await logMusicAction({
    roomId: roomKey(roomId),
    userId: user.id,
    username: user.username ?? user.displayName,
    action: "Pause",
  });

  emitSongSse(roomId, {
    type: "song_paused",
    roomId: roomKey(roomId),
    currentSong: toPublicCurrent(rt),
    queue: rt.queue.filter((q) => q.status === "queued").map(toPublicQueueItem),
    elapsed: rt.current.elapsedMs / 1000,
    paused: true,
  });

  return { ok: true as const, current: toPublicCurrent(rt) };
}

export async function songQueueResume(roomId: string, user: User) {
  const room = getChatRoom(roomId);
  if (!room) return { ok: false as const, error: "Oda bulunamadı" };
  await songQueueEnsureLoaded(roomId);
  const rt = runtime(roomId);
  if (!rt.current.videoId) return { ok: false as const, error: "Çalan şarkı yok" };
  const legacyNow = listMusicQueue(roomId)[0] ?? null;
  if (!canModerate(user, room, legacyNow)) {
    return { ok: false as const, error: "Yetki yok" };
  }
  if (!rt.current.paused) return { ok: true as const, current: toPublicCurrent(rt) };

  rt.current.paused = false;
  rt.current.pausedAt = null;
  rt.current.startedAt = Date.now();
  scheduleAutoFinish(roomId, rt);
  await persistCurrent(roomId, rt);

  await logMusicAction({
    roomId: roomKey(roomId),
    userId: user.id,
    username: user.username ?? user.displayName,
    action: "Resume",
  });

  emitSongSse(roomId, {
    type: "song_resumed",
    roomId: roomKey(roomId),
    currentSong: toPublicCurrent(rt),
    queue: rt.queue.filter((q) => q.status === "queued").map(toPublicQueueItem),
    elapsed: computeElapsedMs(rt) / 1000,
    paused: false,
  });

  return { ok: true as const, current: toPublicCurrent(rt) };
}

export async function songQueueRemove(
  roomId: string,
  user: User,
  queueId: string,
) {
  const room = getChatRoom(roomId);
  if (!room) return { ok: false as const, error: "Oda bulunamadı" };
  await songQueueEnsureLoaded(roomId);
  const rt = runtime(roomId);
  const idx = rt.queue.findIndex((q) => q.id === queueId);
  if (idx < 0) return { ok: false as const, error: "Kuyruk öğesi bulunamadı" };
  const item = rt.queue[idx]!;
  const legacyNow = listMusicQueue(roomId)[0] ?? null;
  const isOwner = item.userId === user.id;
  const isMod = canModerate(user, room, legacyNow);
  if (!isOwner && !isMod) {
    return { ok: false as const, error: "Yetki yok" };
  }
  if (item.status === "playing") {
    return { ok: false as const, error: "Çalan şarkı silinemez; önce atlayın" };
  }

  item.status = "removed";
  rt.queue.splice(idx, 1);
  rt.queue.forEach((q, i) => {
    q.position = i;
  });

  try {
    await prisma.roomSongQueue.update({
      where: { id: queueId },
      data: { status: "removed" },
    });
  } catch {
    /* */
  }

  await logMusicAction({
    roomId: roomKey(roomId),
    userId: user.id,
    username: user.username ?? user.displayName,
    action: "Queue Remove",
    metadata: { queueId, videoId: item.videoId },
  });

  emitSongSse(roomId, {
    type: "song_removed",
    roomId: roomKey(roomId),
    queueId,
    currentSong: rt.current.videoId ? toPublicCurrent(rt) : null,
    queue: rt.queue.filter((q) => q.status === "queued").map(toPublicQueueItem),
    elapsed: computeElapsedMs(rt) / 1000,
    paused: rt.current.paused,
  });

  return { ok: true as const, queue: rt.queue.map(toPublicQueueItem) };
}

export async function songQueueClear(roomId: string, user: User) {
  const room = getChatRoom(roomId);
  if (!room) return { ok: false as const, error: "Oda bulunamadı" };
  const legacyNow = listMusicQueue(roomId)[0] ?? null;
  if (!canModerate(user, room, legacyNow)) {
    return { ok: false as const, error: "Yetki yok" };
  }
  const rt = runtime(roomId);
  rt.queue = rt.queue.filter((q) => q.status === "playing");
  try {
    await prisma.roomSongQueue.updateMany({
      where: { roomId: roomKey(roomId), status: "queued" },
      data: { status: "removed" },
    });
  } catch {
    /* */
  }
  emitQueue(roomId, "queue_updated");
  return { ok: true as const, queue: rt.queue.map(toPublicQueueItem) };
}

function extractYoutubeId(raw: string): string | null {
  try {
    const u = new URL(raw.trim());
    if (u.hostname.includes("youtu.be")) {
      return u.pathname.replace("/", "").slice(0, 11);
    }
    return u.searchParams.get("v")?.slice(0, 11) ?? null;
  } catch {
    const m = raw.match(/(?:v=|youtu\.be\/)([a-zA-Z0-9_-]{6,})/);
    return m?.[1] ?? null;
  }
}

/** YouTube Data API v3 arama — stream URL üretmez. */
export { formatIso8601Duration };
