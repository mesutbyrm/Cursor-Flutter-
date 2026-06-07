import type { Server as HttpServer } from "node:http";
import { Server } from "socket.io";
import { getChatRoom, getDjState, resolveRoomId } from "../lib/chatRoomStore";

let io: Server | null = null;

export function initGiftSocket(httpServer: HttpServer) {
  io = new Server(httpServer, {
    cors: { origin: true, credentials: true },
    path: "/socket.io",
  });

  io.on("connection", (socket) => {
    socket.on("joinStream", (payload: { streamId?: string; userId?: string }) => {
      const id = payload?.streamId?.trim();
      if (id) socket.join(streamRoom(id));
    });

    socket.on("leaveStream", (payload: { streamId?: string }) => {
      const id = payload?.streamId?.trim();
      if (id) socket.leave(streamRoom(id));
    });

    socket.on("joinRoom", (payload: { roomId?: string }) => {
      const id = payload?.roomId?.trim();
      if (id) socket.join(voiceRoom(id));
    });

    socket.on("leaveRoom", (payload: { roomId?: string }) => {
      const id = payload?.roomId?.trim();
      if (id) socket.leave(voiceRoom(id));
    });

    socket.on("joinPk", (payload: { battleId?: string }) => {
      const id = payload?.battleId?.trim();
      if (id) socket.join(pkBattleRoom(id));
    });

    socket.on("leavePk", (payload: { battleId?: string }) => {
      const id = payload?.battleId?.trim();
      if (id) socket.leave(pkBattleRoom(id));
    });
  });

  return io;
}

function streamRoom(streamId: string) {
  return `stream:${streamId}`;
}

function voiceRoom(roomId: string) {
  return `room:${roomId}`;
}

function pkBattleRoom(battleId: string) {
  return `pk:${battleId}`;
}

export function emitGiftEvent(streamId: string, payload: Record<string, unknown>) {
  if (!io) return;
  io.to(streamRoom(streamId)).emit("gift", payload);
  io.to(streamRoom(streamId)).emit("giftSent", payload);
}

export function emitStreamMessage(
  streamId: string,
  payload: Record<string, unknown>,
) {
  if (!io) return;
  const room = streamRoom(streamId);
  io.to(room).emit("streamMessage", payload);
  io.to(room).emit("chatMessage", payload);
  io.to(room).emit("message", payload);
}

export function emitStreamViewerCount(streamId: string, viewerCount: number) {
  if (!io) return;
  const payload = { streamId, viewerCount, viewers: viewerCount };
  const room = streamRoom(streamId);
  io.to(room).emit("viewerCount", payload);
  io.to(room).emit("viewerCountUpdated", payload);
}

export function emitStreamEnded(
  streamId: string,
  payload: Record<string, unknown> = {},
) {
  if (!io) return;
  const body = { streamId, event: "STREAM_ENDED", ...payload };
  const room = streamRoom(streamId);
  io.to(room).emit("streamEnded", body);
  io.to(room).emit("STREAM_ENDED", body);
}

/** Canlı yayın PK güncellemesi — web ve mobil senkronu */
export function emitPkBattleUpdate(
  streamId: string,
  battle: Record<string, unknown>,
) {
  if (!io) return;
  const payload = { streamId, battle, pk: battle, event: "PK_UPDATED" };
  const room = streamRoom(streamId);
  io.to(room).emit("pkBattle", payload);
  io.to(room).emit("pkBattleUpdated", payload);
  io.to(room).emit("PK_UPDATED", payload);
  const opponentId =
    battle.opponentStreamId ?? battle.opponentLiveStreamId;
  if (typeof opponentId === "string" && opponentId.trim()) {
    const oppRoom = streamRoom(opponentId.trim());
    io.to(oppRoom).emit("pkBattle", payload);
    io.to(oppRoom).emit("pkBattleUpdated", payload);
    io.to(oppRoom).emit("PK_UPDATED", payload);
  }
}

/** Birleşik PK socket olayları — pk:invite, pk:accept, pk:score-update, … */
export function emitPkBattleEvent(
  battle: Record<string, unknown>,
  eventName: string,
  extra: Record<string, unknown> = {},
) {
  if (!io) return;
  const battleId = String(battle.id ?? "");
  const payload = { battle, pk: battle, event: eventName, ...extra };

  const targets = new Set<string>();
  const voiceA = battle.voiceRoomId;
  const voiceB = battle.opponentVoiceRoomId;
  const streamA = battle.liveStreamId;
  const streamB = battle.opponentLiveStreamId;

  if (typeof voiceA === "string" && voiceA.trim()) {
    for (const key of voiceRoomTargets(voiceA)) targets.add(voiceRoom(key));
  }
  if (typeof voiceB === "string" && voiceB.trim()) {
    for (const key of voiceRoomTargets(voiceB)) targets.add(voiceRoom(key));
  }
  if (typeof streamA === "string" && streamA.trim()) {
    targets.add(streamRoom(streamA.trim()));
  }
  if (typeof streamB === "string" && streamB.trim()) {
    targets.add(streamRoom(streamB.trim()));
  }
  if (battleId) targets.add(pkBattleRoom(battleId));

  for (const room of targets) {
    io.to(room).emit(eventName, payload);
    io.to(room).emit("pkBattle", payload);
    io.to(room).emit("pkBattleUpdated", payload);
  }

  if (typeof streamA === "string" && streamA.trim()) {
    emitPkBattleUpdate(streamA.trim(), battle);
  }
}

function voiceRoomTargets(roomIdOrSlug: string): string[] {
  const canonical = resolveRoomId(roomIdOrSlug);
  const room = getChatRoom(roomIdOrSlug);
  const keys = new Set<string>([canonical]);
  if (room?.slug?.trim()) keys.add(room.slug.trim());
  if (roomIdOrSlug.trim()) keys.add(roomIdOrSlug.trim());
  return [...keys];
}

export function emitGiftRoomEvent(roomId: string, payload: Record<string, unknown>) {
  if (!io) return;
  for (const key of voiceRoomTargets(roomId)) {
    io.to(voiceRoom(key)).emit("gift", payload);
    io.to(voiceRoom(key)).emit("giftSent", payload);
  }
}

export function emitChatRoomMessage(
  roomId: string,
  payload: Record<string, unknown>,
) {
  if (!io) return;
  for (const key of voiceRoomTargets(roomId)) {
    io.to(voiceRoom(key)).emit("chatMessage", payload);
    io.to(voiceRoom(key)).emit("message", payload);
    io.to(voiceRoom(key)).emit("roomMessage", payload);
  }
}

/** Oda üye listesi — web ve mobil gerçek zamanlı presence senkronu */
/** DJ / müzik kuyruğu güncellemesi — SSE `type: dj` (mobil dinler). */
export function emitChatRoomDjUpdate(roomId: string) {
  if (!io) return;
  const canonical = resolveRoomId(roomId);
  const dj = getDjState(roomId, null);
  const payload = {
    type: "dj",
    event: "QUEUE_UPDATED",
    roomId: canonical,
    playing: dj.playing,
    musicUrl: dj.musicUrl,
    nowPlaying: dj.nowPlaying,
    musicQueue: dj.musicQueue,
    queueLength: dj.musicQueue.length,
  };
  for (const key of voiceRoomTargets(roomId)) {
    io.to(voiceRoom(key)).emit("dj", payload);
    io.to(voiceRoom(key)).emit("music", payload);
    io.to(voiceRoom(key)).emit("QUEUE_UPDATED", payload);
    io.to(voiceRoom(key)).emit("CURRENT_SONG_CHANGED", payload);
  }
}

export function emitChatRoomPresence(
  roomId: string,
  users: Record<string, unknown>[],
  delta?: { joined?: Record<string, unknown>; leftUserId?: string },
) {
  if (!io) return;
  const canonical = resolveRoomId(roomId);
  const payload = { users, roomId: canonical };
  for (const key of voiceRoomTargets(roomId)) {
    io.to(voiceRoom(key)).emit("roomUsers", payload);
    io.to(voiceRoom(key)).emit("presenceUpdated", payload);
    if (delta?.joined) {
      io.to(voiceRoom(key)).emit("userJoined", {
        user: delta.joined,
        users: payload.users,
      });
    }
    if (delta?.leftUserId) {
      io.to(voiceRoom(key)).emit("userLeft", {
        userId: delta.leftUserId,
        users: payload.users,
      });
    }
  }
}
