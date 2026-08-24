import { Router } from "express";
import { prisma } from "../lib/prisma";
import { ok, fail } from "../lib/response";
import { requireAuth } from "../middleware/requireAuth";
import { optionalAuth } from "../middleware/optionalAuth";
import { generateTrtcUserSig } from "../lib/trtcUserSig";
import {
  addLiveStreamMessage,
  endLiveStream,
  getLiveStream,
  joinLiveStream,
  leaveLiveStream,
  listLiveStreams,
  upsertLiveStream,
} from "../lib/liveStreamStore";
import {
  assignSeat,
  getChatRoom,
  getDjState,
  joinPresence,
  leavePresence,
  listChatRooms,
  listPresence,
  resolveRoomId,
} from "../lib/chatRoomStore";
import {
  emitChatRoomMessage,
  emitChatRoomPresence,
  emitStreamEnded,
  emitStreamMessage,
  emitStreamViewerCount,
} from "../socket/giftHub";
import { sendRoomGift, sendStreamGift } from "./gifts";
import {
  acceptPkBattle,
  createPkInvite,
  endPkBattle,
  getActiveBattleForRoom,
  getActiveBattleForStream,
  rejectPkBattle,
} from "../lib/pkBattleService";

export const liveFieldRouter = Router();

async function loadUser(userId: string | undefined) {
  if (!userId) return null;
  return prisma.user.findUnique({ where: { id: userId } });
}

function displayName(user: Awaited<ReturnType<typeof loadUser>>) {
  return user?.displayName ?? user?.username ?? "Kullanıcı";
}

function avatar(user: Awaited<ReturnType<typeof loadUser>>) {
  return user?.avatarUrl ?? undefined;
}

function trtcPayload(userId: string, roomId: string, role = "audience") {
  const cred = generateTrtcUserSig(userId);
  return {
    sdkAppId: cred.sdkAppId,
    userId: cred.userId,
    userSig: cred.userSig,
    roomId,
    expireTime: 86400 * 7,
    role,
  };
}

function normalizeRoomType(value: unknown): "voice" | "stream" {
  const raw = value?.toString().trim().toLowerCase();
  return raw === "stream" || raw === "live" || raw === "video" ? "stream" : "voice";
}

function voiceRoomPayload(roomId: string) {
  const room = getChatRoom(roomId);
  if (!room) return null;
  const canonical = resolveRoomId(roomId);
  const users = listPresence(canonical);
  const dj = getDjState(canonical, null);
  return {
    id: canonical,
    roomId: canonical,
    roomType: "voice",
    title: room.nameTr,
    nameTr: room.nameTr,
    slug: room.slug,
    hostId: room.ownerId,
    hostName: room.owner?.displayName,
    hostImage: room.owner?.image,
    status: users.length > 0 ? "live" : "idle",
    viewerCount: users.length,
    onlineCount: users.length,
    userCount: users.length,
    backgroundImage: room.backgroundImage,
    activeDjId: dj.activeDjId ?? room.activeDjId ?? null,
    musicPlaying: room.musicPlaying ?? dj.playing,
    isPkLive: room.isPkLive === true,
    pkActive: room.pkActive === true,
    isLive: users.length > 0,
  };
}

function streamRoomPayload(streamId: string) {
  const stream = getLiveStream(streamId);
  if (!stream) return null;
  return {
    id: stream.id,
    roomId: stream.id,
    roomType: "stream",
    title: stream.title,
    hostId: stream.broadcasterId,
    hostName: stream.broadcasterName,
    hostImage: undefined,
    status: stream.status,
    viewerCount: stream.viewerCount,
    thumbnailUrl: stream.thumbnailUrl,
  };
}

function giftRanking(roomId: string, roomType: "voice" | "stream") {
  return prisma.giftEvent
    .groupBy({
      by: ["senderId", "senderName"],
      where: roomType === "voice" ? { roomId } : { streamId: roomId },
      _sum: { coinCost: true },
      orderBy: { _sum: { coinCost: "desc" } },
      take: 20,
    })
    .then((rows) =>
      rows.map((row) => ({
        userId: row.senderId,
        userName: row.senderName,
        totalAmount: row._sum.coinCost ?? 0,
      })),
    );
}

liveFieldRouter.post("/trtc/token", requireAuth, async (req, res) => {
  const roomId = req.body?.roomId?.toString().trim();
  if (!roomId) return fail(res, 400, "BAD_REQUEST", "roomId gerekli");
  const role = req.body?.role?.toString().trim() || "audience";
  return ok(res, trtcPayload(req.userId!, roomId, role));
});

liveFieldRouter.post("/live/create-room", requireAuth, async (req, res) => {
  const user = await loadUser(req.userId);
  if (!user) return fail(res, 401, "UNAUTHORIZED", "Oturum gerekli");
  const streamId =
    req.body?.id?.toString().trim() ||
    req.body?.streamId?.toString().trim() ||
    `stream-${user.id}-${Date.now()}`;
  const stream = upsertLiveStream({
    id: streamId,
    title: req.body?.title?.toString().trim() || "Canlı yayın",
    description: req.body?.description?.toString().trim() || undefined,
    category: req.body?.category?.toString().trim() || undefined,
    broadcasterId: user.id,
    broadcasterName: displayName(user),
    thumbnailUrl:
      req.body?.thumbnailUrl?.toString().trim() ||
      req.body?.coverUrl?.toString().trim() ||
      undefined,
    status: "live",
    viewerCount: 0,
    createdAt: new Date().toISOString(),
  });
  return ok(res, {
    stream: streamRoomPayload(stream.id),
    room: streamRoomPayload(stream.id),
    trtc: trtcPayload(user.id, stream.id, "host"),
  });
});

liveFieldRouter.post("/live/join-room", requireAuth, async (req, res) => {
  const user = await loadUser(req.userId);
  if (!user) return fail(res, 401, "UNAUTHORIZED", "Oturum gerekli");
  const roomId = req.body?.roomId?.toString().trim();
  if (!roomId) return fail(res, 400, "BAD_REQUEST", "roomId gerekli");
  const roomType = normalizeRoomType(req.body?.roomType);

  if (roomType === "voice") {
    const room = getChatRoom(roomId);
    if (!room) return fail(res, 404, "NOT_FOUND", "Oda bulunamadı");
    const joined = await joinPresence(room.id, user, {
      nickname: req.body?.nickname?.toString(),
    });
    if (!joined || "full" in joined) return fail(res, 409, "ROOM_FULL", "Oda dolu");
    if ("banned" in joined && joined.banned) {
      return fail(res, 403, "FORBIDDEN", "Bu odadan yasaklandınız");
    }
    if (joined.systemMsg) emitChatRoomMessage(room.id, joined.systemMsg);
    const currentPresence = listPresence(room.id);
    const self = currentPresence.find((p) => p.id === user.id);
    emitChatRoomPresence(room.id, currentPresence as unknown as Record<string, unknown>[], {
      joined: self as unknown as Record<string, unknown> | undefined,
    });
    const canonical = resolveRoomId(room.id);
    return ok(res, {
      room: voiceRoomPayload(canonical),
      trtc: trtcPayload(user.id, `voice_room_${canonical}`, "audience"),
      user: {
        id: user.id,
        name: displayName(user),
        image: avatar(user),
        isHost: room.ownerId === user.id,
        seatIndex: self?.seatIndex ?? null,
      },
      participants: currentPresence.map((p) => ({
        userId: p.id,
        userName: p.name,
        userImage: p.image,
        seatIndex: p.seatIndex ?? null,
        role: p.chatRole,
      })),
      seats: currentPresence
        .filter((p) => typeof p.seatIndex === "number")
        .map((p) => ({
          seatIndex: p.seatIndex,
          userId: p.id,
          userName: p.name,
          userImage: p.image,
          isMicOn: p.isSpeaking === true,
        })),
      giftRanking: await giftRanking(canonical, "voice"),
      pkStatus: await getActiveBattleForRoom(canonical),
    });
  }

  const stream = getLiveStream(roomId);
  if (!stream || stream.status !== "live") {
    return fail(res, 404, "NOT_FOUND", "Yayın aktif değil");
  }
  const viewerCount = joinLiveStream(stream.id, user.id);
  emitStreamViewerCount(stream.id, viewerCount);
  return ok(res, {
    room: streamRoomPayload(stream.id),
    trtc: trtcPayload(user.id, stream.id, "audience"),
    user: {
      id: user.id,
      name: displayName(user),
      image: avatar(user),
      isHost: stream.broadcasterId === user.id,
    },
    participants: [],
    seats: [],
    giftRanking: await giftRanking(stream.id, "stream"),
    pkStatus: await getActiveBattleForStream(stream.id),
  });
});

liveFieldRouter.post("/live/leave-room", requireAuth, async (req, res) => {
  const roomId = req.body?.roomId?.toString().trim();
  if (!roomId) return fail(res, 400, "BAD_REQUEST", "roomId gerekli");
  const roomType = normalizeRoomType(req.body?.roomType);
  if (roomType === "voice") {
    const result = leavePresence(roomId, req.userId!);
    if (result.systemMsg) emitChatRoomMessage(roomId, result.systemMsg);
    emitChatRoomPresence(roomId, result.presence as unknown as Record<string, unknown>[], {
      leftUserId: req.userId!,
    });
    return ok(res, { message: "Odadan ayrıldınız", roomId: resolveRoomId(roomId) });
  }
  const count = leaveLiveStream(roomId, req.userId!);
  emitStreamViewerCount(roomId, count);
  return ok(res, { message: "Odadan ayrıldınız", roomId, viewerCount: count });
});

liveFieldRouter.post("/live/heartbeat", requireAuth, async (req, res) => {
  const roomId = req.body?.roomId?.toString().trim();
  if (!roomId) return fail(res, 400, "BAD_REQUEST", "roomId gerekli");
  const roomType = normalizeRoomType(req.body?.roomType);
  const count =
    roomType === "voice"
      ? listPresence(roomId).length
      : getLiveStream(roomId)?.viewerCount ?? 0;
  return ok(res, {
    onlineCount: count,
    staleRemoved: 0,
    serverTime: new Date().toISOString(),
  });
});

liveFieldRouter.get("/live/rooms", optionalAuth, async (req, res) => {
  const type = req.query.type?.toString().toLowerCase() ?? "all";
  const page = Math.max(1, Number(req.query.page ?? 1));
  const limit = Math.min(100, Math.max(1, Number(req.query.limit ?? 30)));
  const voiceRooms =
    type === "stream"
      ? []
      : listChatRooms().map((room) => ({
          ...voiceRoomPayload(room.id),
          slug: room.slug,
          icon: room.icon,
          isLive: true,
        }));
  const streams =
    type === "voice"
      ? []
      : listLiveStreams().map((stream) => ({
          ...streamRoomPayload(stream.id),
          isLive: stream.status === "live",
        }));
  const all = [...voiceRooms, ...streams].filter(Boolean);
  const start = (page - 1) * limit;
  const rooms = all.slice(start, start + limit);
  return ok(res, {
    rooms,
    items: rooms,
    pagination: {
      page,
      limit,
      total: all.length,
      totalPages: Math.max(1, Math.ceil(all.length / limit)),
    },
  });
});

liveFieldRouter.get("/live/online-users", optionalAuth, async (req, res) => {
  const roomId = req.query.roomId?.toString().trim();
  if (!roomId) return fail(res, 400, "BAD_REQUEST", "roomId gerekli");
  const roomType = normalizeRoomType(req.query.roomType);
  const users =
    roomType === "voice"
      ? listPresence(roomId).map((p) => ({
          userId: p.id,
          userName: p.name,
          userImage: p.image,
          nickname: p.nickname,
          seatIndex: p.seatIndex ?? null,
          isMicOn: p.isSpeaking === true,
        }))
      : [];
  return ok(res, { users, onlineCount: users.length });
});

liveFieldRouter.get("/live/seats", optionalAuth, async (req, res) => {
  const roomId = req.query.roomId?.toString().trim();
  if (!roomId) return fail(res, 400, "BAD_REQUEST", "roomId gerekli");
  const seats = listPresence(roomId)
    .filter((p) => typeof p.seatIndex === "number")
    .map((p) => ({
      seatIndex: p.seatIndex,
      userId: p.id,
      userName: p.name,
      userImage: p.image,
      isMicOn: p.isSpeaking === true,
    }));
  return ok(res, { roomId: resolveRoomId(roomId), totalSeats: 15, seats });
});

liveFieldRouter.post("/live/seats", requireAuth, async (req, res) => {
  const roomId = req.body?.roomId?.toString().trim();
  if (!roomId) return fail(res, 400, "BAD_REQUEST", "roomId gerekli");
  const action = req.body?.action?.toString().toLowerCase() || "take";
  if (action === "leave") {
    return ok(res, { roomId: resolveRoomId(roomId), seats: [] });
  }
  const seatIndex = Number(req.body?.seatIndex ?? 1);
  const user = await loadUser(req.userId);
  if (!user) return fail(res, 401, "UNAUTHORIZED", "Oturum gerekli");
  await joinPresence(roomId, user);
  const result = assignSeat(roomId, user, seatIndex, req.body?.targetUserId?.toString());
  if (!result.ok) return fail(res, 403, "FORBIDDEN", result.error ?? "Koltuk atanamadı");
  emitChatRoomPresence(roomId, result.presence as unknown as Record<string, unknown>[]);
  return ok(res, {
    roomId: resolveRoomId(roomId),
    seats: listPresence(roomId).filter((p) => typeof p.seatIndex === "number"),
  });
});

liveFieldRouter.post("/live/message", requireAuth, async (req, res) => {
  const user = await loadUser(req.userId);
  if (!user) return fail(res, 401, "UNAUTHORIZED", "Oturum gerekli");
  const roomId = req.body?.roomId?.toString().trim();
  const content =
    req.body?.content?.toString() ??
    req.body?.message?.toString() ??
    req.body?.text?.toString() ??
    "";
  if (!roomId || !content.trim()) {
    return fail(res, 400, "BAD_REQUEST", "roomId ve content gerekli");
  }
  const row = addLiveStreamMessage(
    roomId,
    { id: user.id, name: displayName(user), image: avatar(user) },
    content,
  );
  if (!row) return fail(res, 404, "NOT_FOUND", "Yayın bulunamadı");
  emitStreamMessage(roomId, row);
  return ok(res, { message: row });
});

liveFieldRouter.get("/live/gift-types", optionalAuth, async (_req, res) => {
  const gifts = await prisma.gift.findMany({
    where: {
      enabled: true,
      OR: [{ platform: "all" }, { platform: "mobile" }],
    },
    orderBy: [{ sortOrder: "asc" }, { price: "asc" }],
  });
  return ok(res, {
    giftTypes: gifts.map((gift) => ({
      id: gift.id,
      slug: gift.slug,
      name: gift.name,
      icon: gift.icon,
      price: gift.price,
      animation: gift.animation,
      assetUrl: gift.animation,
      assetType: gift.animationType,
      sound: gift.sound,
      sortOrder: gift.sortOrder,
    })),
  });
});

liveFieldRouter.post("/live/gift/send", requireAuth, async (req, res) => {
  const roomId = req.body?.roomId?.toString().trim();
  if (!roomId) return fail(res, 400, "BAD_REQUEST", "roomId gerekli");
  const roomType = normalizeRoomType(req.body?.roomType);
  const body = {
    ...req.body,
    receiverId: req.body?.receiverId ?? req.body?.recipientId ?? req.body?.receiverUserId,
    giftTypeId: req.body?.giftTypeId ?? req.body?.giftId,
    platform: req.body?.platform ?? "mobile",
  };
  return roomType === "voice"
    ? sendRoomGift(roomId, body, req.userId, res)
    : sendStreamGift(roomId, body, req.userId, res);
});

liveFieldRouter.get("/live/pk", requireAuth, async (req, res) => {
  const roomId = req.query.roomId?.toString().trim();
  if (!roomId) return fail(res, 400, "BAD_REQUEST", "roomId gerekli");
  const battle =
    getChatRoom(roomId) != null
      ? await getActiveBattleForRoom(resolveRoomId(roomId))
      : await getActiveBattleForStream(roomId);
  return ok(res, { battle });
});

liveFieldRouter.post("/live/pk", requireAuth, async (req, res) => {
  const action = req.body?.action?.toString().toLowerCase() || "request";
  const roomId = req.body?.roomId?.toString().trim();
  const targetRoomId =
    req.body?.targetRoomId?.toString().trim() ||
    req.body?.opponentRoomId?.toString().trim();
  const battleId = req.body?.battleId?.toString().trim();
  if (action === "accept" && battleId) {
    const result = await acceptPkBattle(battleId, req.userId!);
    if (!result.ok) return fail(res, 400, "BAD_REQUEST", result.error);
    return ok(res, { battle: result.battle });
  }
  if ((action === "reject" || action === "cancel") && battleId) {
    const result = await rejectPkBattle(battleId, req.userId!);
    if (!result.ok) return fail(res, 400, "BAD_REQUEST", result.error);
    return ok(res, { battle: result.battle });
  }
  if (action === "end" && battleId) {
    const result = await endPkBattle(battleId, "manual");
    if (!result.ok) return fail(res, 400, "BAD_REQUEST", result.error);
    return ok(res, { battle: result.battle });
  }
  if (!roomId || !targetRoomId) {
    return fail(res, 400, "BAD_REQUEST", "roomId ve targetRoomId gerekli");
  }
  const voice = getChatRoom(roomId) != null || getChatRoom(targetRoomId) != null;
  const result = await createPkInvite({
    battleType: voice ? "voice_room" : "live_stream",
    challengerId: req.userId!,
    voiceRoomId: voice ? resolveRoomId(roomId) : undefined,
    opponentVoiceRoomId: voice ? resolveRoomId(targetRoomId) : undefined,
    liveStreamId: voice ? undefined : roomId,
    opponentLiveStreamId: voice ? undefined : targetRoomId,
    opponentId: req.body?.guestUserId?.toString(),
    durationSeconds: Number(req.body?.durationSeconds ?? req.body?.durationSec ?? 300),
  });
  if (!result.ok) return fail(res, 400, "BAD_REQUEST", result.error);
  return ok(res, { battle: result.battle });
});

liveFieldRouter.post("/live/pk/score", requireAuth, async (req, res) => {
  const battleId = req.body?.battleId?.toString().trim();
  if (!battleId) return fail(res, 400, "BAD_REQUEST", "battleId gerekli");
  return ok(res, {
    battleId,
    amount: Number(req.body?.amount ?? 0),
    message: "PK skorları hediye eventleri ile güncellenir",
  });
});

liveFieldRouter.post("/live/rooms/:id/end", requireAuth, async (req, res) => {
  const streamId = req.params.id;
  const stream = getLiveStream(streamId);
  if (!stream) return fail(res, 404, "NOT_FOUND", "Yayın bulunamadı");
  if (stream.broadcasterId !== req.userId) {
    return fail(res, 403, "FORBIDDEN", "Yayını yalnızca yayıncı bitirebilir");
  }
  endLiveStream(streamId);
  emitStreamEnded(streamId, { streamId, reason: "ended" });
  return ok(res, { ended: true, streamId });
});
