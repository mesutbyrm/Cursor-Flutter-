import { randomUUID } from "node:crypto";
import type { User } from "@prisma/client";
import { prisma } from "./prisma";
import { logMusicAction } from "./musicActionLog";

export type PersistedMusicQueueItem = {
  id: string;
  roomId: string;
  userId: string;
  username: string | null;
  artist: string | null;
  songName: string;
  youtubeId: string;
  duration: string | null;
  thumbUrl: string | null;
  status: string;
  createdAt: Date;
};

const memoryByRoom = new Map<string, PersistedMusicQueueItem[]>();

function roomKey(roomId: string) {
  return roomId.trim();
}

function memoryList(roomId: string) {
  const key = roomKey(roomId);
  let list = memoryByRoom.get(key);
  if (!list) {
    list = [];
    memoryByRoom.set(key, list);
  }
  return list;
}

function rowToItem(row: {
  id: string;
  roomId: string;
  userId: string;
  username: string | null;
  artist: string | null;
  songName: string;
  youtubeId: string;
  duration: string | null;
  thumbUrl: string | null;
  status: string;
  createdAt: Date;
}): PersistedMusicQueueItem {
  return { ...row };
}

async function loadFromDb(roomId: string): Promise<PersistedMusicQueueItem[]> {
  try {
    const rows = await prisma.musicQueue.findMany({
      where: {
        roomId: roomKey(roomId),
        status: { in: ["queued", "playing"] },
      },
      orderBy: { createdAt: "asc" },
    });
    return rows.map(rowToItem);
  } catch {
    return memoryList(roomId);
  }
}

async function syncMemory(roomId: string) {
  const dbRows = await loadFromDb(roomId);
  if (dbRows.length > 0) {
    memoryByRoom.set(roomKey(roomId), dbRows);
  }
  return memoryList(roomId);
}

export async function getRoomMusicItems(roomId: string) {
  await syncMemory(roomId);
  const list = memoryList(roomId);
  const playing = list.find((i) => i.status === "playing") ?? null;
  const queued = list.filter((i) => i.status === "queued");
  return { playing, queued, all: list };
}

export async function countQueued(roomId: string) {
  const { queued, playing } = await getRoomMusicItems(roomId);
  return (playing ? 1 : 0) + queued.length;
}

export async function appendMusicItem(input: {
  roomId: string;
  user: User;
  artist: string | null;
  songName: string;
  youtubeId: string;
  duration: string | null;
  thumbUrl: string | null;
}) {
  const item: PersistedMusicQueueItem = {
    id: randomUUID(),
    roomId: roomKey(input.roomId),
    userId: input.user.id,
    username: input.user.username ?? input.user.displayName ?? null,
    artist: input.artist,
    songName: input.songName,
    youtubeId: input.youtubeId,
    duration: input.duration,
    thumbUrl: input.thumbUrl,
    status: "queued",
    createdAt: new Date(),
  };

  const list = memoryList(input.roomId);
  list.push(item);

  try {
    await prisma.musicQueue.create({
      data: {
        id: item.id,
        roomId: item.roomId,
        userId: item.userId,
        username: item.username,
        artist: item.artist,
        songName: item.songName,
        youtubeId: item.youtubeId,
        duration: item.duration,
        thumbUrl: item.thumbUrl,
        status: item.status,
        createdAt: item.createdAt,
      },
    });
  } catch {
    // Bellek kuyruğu yeterli
  }

  await logMusicAction({
    roomId: item.roomId,
    userId: item.userId,
    username: item.username,
    action: "request",
    metadata: {
      songName: item.songName,
      artist: item.artist,
      youtubeId: item.youtubeId,
    },
  });

  return item;
}

export async function markPlaying(roomId: string, itemId: string) {
  const list = memoryList(roomId);
  for (const row of list) {
    if (row.status === "playing" && row.id !== itemId) {
      row.status = "played";
    }
  }
  const target = list.find((i) => i.id === itemId);
  if (target) target.status = "playing";

  try {
    await prisma.musicQueue.updateMany({
      where: { roomId: roomKey(roomId), status: "playing", NOT: { id: itemId } },
      data: { status: "played" },
    });
    await prisma.musicQueue.update({
      where: { id: itemId },
      data: { status: "playing" },
    });
  } catch {
    // ignore
  }

  await logMusicAction({
    roomId: roomKey(roomId),
    userId: target?.userId,
    username: target?.username,
    action: "play",
    metadata: { itemId, songName: target?.songName },
  });
}

export async function advanceRoomQueue(roomId: string) {
  const list = memoryList(roomId);
  const playingIdx = list.findIndex((i) => i.status === "playing");
  if (playingIdx >= 0) {
    const done = list.splice(playingIdx, 1)[0]!;
    try {
      await prisma.musicQueue.update({
        where: { id: done.id },
        data: { status: "played" },
      });
    } catch {
      // ignore
    }
  } else if (list.length > 0 && list[0]!.status === "queued") {
    list.shift();
  }

  const next = list.find((i) => i.status === "queued");
  if (next) {
    next.status = "playing";
    try {
      await prisma.musicQueue.update({
        where: { id: next.id },
        data: { status: "playing" },
      });
    } catch {
      // ignore
    }
  }

  return next ?? null;
}

export async function clearRoomQueue(roomId: string, actor?: User) {
  const list = memoryList(roomId);
  const ids = list.map((i) => i.id);
  list.splice(0, list.length);

  try {
    if (ids.length > 0) {
      await prisma.musicQueue.updateMany({
        where: { id: { in: ids } },
        data: { status: "removed" },
      });
    }
  } catch {
    // ignore
  }

  await logMusicAction({
    roomId: roomKey(roomId),
    userId: actor?.id,
    username: actor?.username ?? actor?.displayName,
    action: "close",
    metadata: { cleared: ids.length },
  });
}

export async function removeQueueItemById(
  roomId: string,
  itemId: string,
  actor?: User,
) {
  const list = memoryList(roomId);
  const idx = list.findIndex((i) => i.id === itemId);
  if (idx < 0) return null;
  const [removed] = list.splice(idx, 1);
  try {
    await prisma.musicQueue.update({
      where: { id: itemId },
      data: { status: "removed" },
    });
  } catch {
    // ignore
  }
  await logMusicAction({
    roomId: roomKey(roomId),
    userId: actor?.id,
    username: actor?.username ?? actor?.displayName,
    action: "stop",
    metadata: { itemId, songName: removed?.songName },
  });
  return removed ?? null;
}

export function getMemoryQueue(roomId: string) {
  return [...memoryList(roomId)];
}

export async function logJetonDebit(input: {
  roomId: string;
  user: User;
  amount: number;
  balanceAfter: number;
  songName: string;
}) {
  await logMusicAction({
    roomId: roomKey(input.roomId),
    userId: input.user.id,
    username: input.user.username ?? input.user.displayName,
    action: "debit",
    metadata: {
      amount: input.amount,
      balanceAfter: input.balanceAfter,
      songName: input.songName,
    },
  });
}

export async function logUnauthorized(input: {
  roomId: string;
  user: User;
  attempted: string;
}) {
  await logMusicAction({
    roomId: roomKey(input.roomId),
    userId: input.user.id,
    username: input.user.username ?? input.user.displayName,
    action: "unauthorized",
    metadata: { attempted: input.attempted },
  });
}
