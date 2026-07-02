import { Request, Response, Router } from "express";

type RoomRequest = Request<{ roomId: string }>;
type RoomTargetRequest = Request<{ roomId: string; targetUserId: string }>;
type RoomItemRequest = Request<{ roomId: string; itemId: string }>;
type RoomWordRequest = Request<{ roomId: string; word: string }>;
import { optionalAuth } from "../middleware/optionalAuth";
import { requireAuth } from "../middleware/requireAuth";
import { fail, ok } from "../lib/response";
import {
  addTextMessage,
  clearRoomMessages,
  approveSpeak,
  banRoomUser,
  cancelSpeakRequest,
  getChatRoom,
  getDjState,
  joinPresence,
  leavePresence,
  listChatRooms,
  listMessages,
  listPresence,
  listRoomBans,
  listSiteBackgrounds,
  listSpeakRequests,
  loadUser,
  createVoiceChatRoom,
  requestSpeak,
  resolveRoomId,
  roomPrivileges,
  setDjMusic,
  setRoomBackground,
  unbanRoomUser,
  listMusicQueue,
  requestMusicQueue,
  requestMusicByQuery,
  searchYoutube,
  resolveYoutubeStreamUrl,
  advanceMusicQueue,
  skipMusicQueue,
  removeMusicQueueItem,
  clearMusicQueue,
  setRoomMusicSettings,
  getRoomMusicSettings,
  POPULAR_MUSIC_SUGGESTIONS,
  addRoomDj,
  removeRoomDj,
  assignSeat,
  MUSIC_REQUEST_JETON,
  listRoomBannedWords,
  addRoomBannedWord,
  removeRoomBannedWord,
  notifyVoiceRoomMentions,
} from "../lib/chatRoomStore";
import {
  emitChatRoomDjUpdate,
  emitChatRoomMessage,
  emitChatRoomPresence,
} from "../socket/giftHub";
import { getActiveBattleForRoom } from "../lib/pkBattleService";
import { listRoomGiftEvents, sendRoomGift } from "./gifts";
import {
  broadcastPkResult,
  handleVoiceRoomPkAction,
} from "./pk_battles";
import { presenceHeartbeat } from "../lib/redis/presence";

export const chatRoomsRouter = Router();

function bodyYoutubeUrl(body: Record<string, unknown>): string {
  const videoId =
    typeof body.videoId === "string" ? body.videoId.trim() : "";
  if (typeof body.youtubeUrl === "string" && body.youtubeUrl.trim()) {
    return body.youtubeUrl.trim();
  }
  if (typeof body.url === "string" && body.url.trim()) {
    return body.url.trim();
  }
  if (videoId) {
    return `https://www.youtube.com/watch?v=${videoId}`;
  }
  return "";
}

/** GET /api/chat/rooms — mobil ham dizi bekler */
chatRoomsRouter.get("/rooms", async (_req, res) => {
  return res.status(200).json(listChatRooms());
});

chatRoomsRouter.post("/rooms/create", requireAuth, async (req, res) => {
  const user = await loadUser(req.userId);
  if (!user) return fail(res, 401, "UNAUTHORIZED", "Oturum açmanız gerekiyor");
  const body = req.body?.room ?? req.body ?? {};
  const vip =
    req.body?.isVip === true ||
    req.body?.vip === true ||
    req.body?.roomType === "vip" ||
    req.body?.type === "vip" ||
    body?.roomType === "vip" ||
    body?.type === "vip";
  const costRaw =
    req.body?.cost ?? req.body?.jeton ?? req.body?.coins ?? req.body?.amount;
  const cost =
    typeof costRaw === "number"
      ? costRaw
      : typeof costRaw === "string"
        ? Number.parseInt(costRaw, 10)
        : undefined;
  const name =
    typeof body?.name === "string"
      ? body.name
      : typeof body?.nameTr === "string"
        ? body.nameTr
        : typeof body?.roomName === "string"
          ? body.roomName
          : typeof body?.title === "string"
            ? body.title
            : typeof req.body?.name === "string"
              ? req.body.name
              : typeof req.body?.nameTr === "string"
                ? req.body.nameTr
                : undefined;
  const description =
    typeof body?.description === "string"
      ? body.description
      : typeof body?.descTr === "string"
        ? body.descTr
        : typeof body?.desc === "string"
          ? body.desc
          : typeof req.body?.description === "string"
            ? req.body.description
            : typeof req.body?.descTr === "string"
              ? req.body.descTr
              : undefined;
  const icon =
    typeof body?.icon === "string"
      ? body.icon
      : typeof req.body?.icon === "string"
        ? req.body.icon
        : undefined;
  if (!name?.trim() || !description?.trim() || !icon?.trim()) {
    return fail(
      res,
      400,
      "BAD_REQUEST",
      "Name, description and icon are required",
    );
  }
  const roomTypeRaw =
    req.body?.roomType ??
    req.body?.type ??
    body?.roomType ??
    body?.type ??
    (vip ? "vip" : undefined);
  const result = await createVoiceChatRoom(user, {
    vip,
    cost,
    name: name.trim(),
    roomType: roomTypeRaw,
  });
  if (!result.ok) {
    const code = result.error?.includes("jeton") ? 402 : 400;
    return fail(res, code, "BAD_REQUEST", result.error ?? "Oda açılamadı");
  }
  return res.status(200).json({
    success: true,
    room: result.room,
    data: { room: result.room },
    newBalance: result.newBalance,
    coinBalance: result.newBalance,
  });
});

chatRoomsRouter.get("/rooms/backgrounds", async (_req, res) => {
  return ok(res, { backgrounds: listSiteBackgrounds() });
});

chatRoomsRouter.get("/youtube-search", requireAuth, async (req, res) => {
  const q = String(req.query.q ?? req.query.query ?? "");
  const items = await searchYoutube(q);
  return res.status(200).json({ items });
});

chatRoomsRouter.get("/youtube-stream", optionalAuth, async (req, res) => {
  const url = String(req.query.url ?? req.query.videoId ?? "");
  const streamUrl = await resolveYoutubeStreamUrl(url);
  if (!streamUrl) {
    return fail(res, 404, "NOT_FOUND", "Ses akışı bulunamadı");
  }
  return res.status(200).json({ streamUrl, url: streamUrl });
});

/** GET /api/chat/youtube-audio — googlevideo akışı (Referer ile proxy; mobil oynatıcı) */
chatRoomsRouter.get("/youtube-audio", optionalAuth, async (req, res) => {
  const url = String(req.query.url ?? "");
  if (!url.startsWith("http")) {
    return fail(res, 400, "INVALID_URL", "Geçersiz akış adresi");
  }
  if (!/googlevideo\.com|youtube\.com\/api\//i.test(url)) {
    return fail(res, 400, "INVALID_URL", "Yalnızca YouTube CDN akışları desteklenir");
  }
  const range = req.headers.range;
  const upstreamHeaders: Record<string, string> = {
    Referer: "https://www.youtube.com/",
    Origin: "https://www.youtube.com",
    "User-Agent":
      "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36",
  };
  if (typeof range === "string" && range.length > 0) {
    upstreamHeaders.Range = range;
  }
  try {
    const upstream = await fetch(url, { headers: upstreamHeaders });
    if (!upstream.ok) {
      return fail(
        res,
        upstream.status,
        "UPSTREAM_ERROR",
        "Akış yüklenemedi",
      );
    }
    res.status(upstream.status);
    const passHeaders = [
      "content-type",
      "content-length",
      "content-range",
      "accept-ranges",
    ];
    for (const h of passHeaders) {
      const v = upstream.headers.get(h);
      if (v) res.setHeader(h, v);
    }
    if (!upstream.body) {
      return res.end();
    }
    const { Readable } = await import("node:stream");
    const { pipeline } = await import("node:stream/promises");
    const nodeStream = Readable.fromWeb(
      upstream.body as import("stream/web").ReadableStream,
    );
    await pipeline(nodeStream, res);
  } catch {
    if (!res.headersSent) {
      return fail(res, 502, "PROXY_ERROR", "Akış aktarılamadı");
    }
    res.end();
  }
});

chatRoomsRouter.get("/music/popular", optionalAuth, async (_req, res) => {
  return res.status(200).json({ items: POPULAR_MUSIC_SUGGESTIONS });
});

chatRoomsRouter.post(
  "/rooms/:roomId/music-stream",
  requireAuth,
  async (req, res) => {
    const roomId = req.params.roomId;
    if (!getChatRoom(roomId)) {
      return fail(res, 404, "NOT_FOUND", "Oda bulunamadı");
    }
    const videoId =
      typeof req.body?.videoId === "string"
        ? req.body.videoId.trim()
        : String(req.query.videoId ?? "").trim();
    const url =
      typeof req.body?.youtubeUrl === "string"
        ? req.body.youtubeUrl.trim()
        : videoId
          ? `https://www.youtube.com/watch?v=${videoId}`
          : String(req.query.url ?? "").trim();
    const streamUrl = await resolveYoutubeStreamUrl(url || videoId);
    if (!streamUrl) {
      return fail(res, 404, "NOT_FOUND", "Ses akışı oluşturulamadı");
    }
    return res.status(200).json({
      streamUrl,
      url: streamUrl,
      videoId: videoId || null,
      expiresInSec: 3600,
    });
  },
);

chatRoomsRouter.get("/rooms/:roomId/music-queue", optionalAuth, async (req, res) => {
  const roomId = req.params.roomId;
  if (!getChatRoom(roomId)) {
    return fail(res, 404, "NOT_FOUND", "Oda bulunamadı");
  }
  const settings = getRoomMusicSettings(roomId);
  const user = await loadUser(req.userId);
  const dj = getDjState(roomId, user);
  return res.status(200).json({
    queue: listMusicQueue(roomId),
    cost: settings.musicRequestCost,
    musicRequestCost: settings.musicRequestCost,
    maxMusicQueue: settings.maxQueueLength,
    musicEnabled: settings.musicEnabled,
    nowPlaying: dj.nowPlaying ?? null,
    playing: dj.playing,
    musicUrl: dj.musicUrl ?? null,
    canRequestMusic: dj.canRequestMusic,
    currentVideoId: dj.currentVideoId,
    currentPosition: dj.currentPosition,
    isPlaying: dj.isPlaying,
    trackStartedAt: dj.trackStartedAt,
    positionMs: dj.positionMs,
  });
});

chatRoomsRouter.post("/rooms/:roomId/song-request", requireAuth, async (req, res) => {
  const roomId = req.params.roomId;
  const user = await loadUser(req.userId);
  if (!user) return fail(res, 401, "UNAUTHORIZED", "Oturum gerekli");
  const title = typeof req.body?.title === "string" ? req.body.title : "";
  const youtubeUrl = bodyYoutubeUrl(req.body ?? {});
  const thumbUrl =
    typeof req.body?.thumbUrl === "string" ? req.body.thumbUrl : null;
  const giftTo =
    typeof req.body?.giftTo === "string"
      ? req.body.giftTo
      : typeof req.body?.giftToUsername === "string"
        ? req.body.giftToUsername
        : null;
  const note =
    typeof req.body?.note === "string"
      ? req.body.note
      : typeof req.body?.message === "string"
        ? req.body.message
        : null;
  const priority = req.body?.priority === true;
  const result = await requestMusicQueue(roomId, user, {
    title,
    youtubeUrl,
    thumbUrl,
    giftTo,
    note,
    artist: typeof req.body?.artist === "string" ? req.body.artist : null,
    songName: typeof req.body?.songName === "string" ? req.body.songName : title,
    duration: typeof req.body?.duration === "string" ? req.body.duration : null,
    priority,
  });
  if (!result.ok) {
    const code =
      result.error?.includes("jeton") || (result as { code?: string }).code === "INSUFFICIENT_JETON"
        ? 402
        : 400;
    return fail(res, code, "BAD_REQUEST", result.error ?? "İstek başarısız");
  }
  emitChatRoomDjUpdate(roomId);
  return res.status(200).json({
    success: true,
    item: result.item,
    queue: result.queue,
    newBalance: result.newBalance,
    coinBalance: result.newBalance,
    cost: MUSIC_REQUEST_JETON,
    musicUrl: result.musicUrl,
    playing: result.playing,
    queuePosition: result.queuePosition,
  });
});

chatRoomsRouter.post(
  "/rooms/:roomId/music-request-by-query",
  requireAuth,
  async (req, res) => {
    const roomId = req.params.roomId;
    if (!getChatRoom(roomId)) {
      return fail(res, 404, "NOT_FOUND", "Oda bulunamadı");
    }
    const user = await loadUser(req.userId);
    if (!user) return fail(res, 401, "UNAUTHORIZED", "Oturum gerekli");
    const query =
      typeof req.body?.query === "string"
        ? req.body.query
        : typeof req.body?.q === "string"
          ? req.body.q
          : "";
    const result = await requestMusicByQuery(roomId, user, query);
    if (!result.ok) {
      const code =
        result.error?.includes("jeton") ||
        (result as { code?: string }).code === "INSUFFICIENT_JETON"
          ? 402
          : 400;
      return fail(res, code, "BAD_REQUEST", result.error ?? "İstek başarısız");
    }
    emitChatRoomDjUpdate(roomId);
    return res.status(200).json({
      success: true,
      item: result.item,
      queue: result.queue,
      newBalance: result.newBalance,
      coinBalance: result.newBalance,
      cost: MUSIC_REQUEST_JETON,
      musicUrl: result.musicUrl,
      playing: result.playing,
      queuePosition: result.queuePosition,
    });
  },
);

chatRoomsRouter.post(
  "/rooms/:roomId/music-queue/complete",
  requireAuth,
  async (req, res) => {
    const roomId = req.params.roomId;
    if (!getChatRoom(roomId)) {
      return fail(res, 404, "NOT_FOUND", "Oda bulunamadı");
    }
    await advanceMusicQueue(roomId);
    const user = await loadUser(req.userId);
    emitChatRoomDjUpdate(roomId);
    return res.status(200).json({
      ...getDjState(roomId, user),
      queue: listMusicQueue(roomId),
    });
  },
);

chatRoomsRouter.post(
  "/rooms/:roomId/music-queue/advance",
  requireAuth,
  async (req, res) => {
    const roomId = req.params.roomId;
    if (!getChatRoom(roomId)) {
      return fail(res, 404, "NOT_FOUND", "Oda bulunamadı");
    }
    const user = await loadUser(req.userId);
    if (!user) return fail(res, 401, "UNAUTHORIZED", "Oturum gerekli");
    const skipped = await skipMusicQueue(roomId, user);
    if (!skipped.ok) {
      return fail(res, 403, "FORBIDDEN", skipped.error ?? "Yetki yok");
    }
    emitChatRoomDjUpdate(roomId);
    return res.status(200).json({
      ...getDjState(roomId, user),
      queue: skipped.queue,
    });
  },
);

chatRoomsRouter.delete(
  "/rooms/:roomId/music-queue/:itemId",
  requireAuth,
  async (req, res) => {
    const roomId = req.params.roomId;
    const user = await loadUser(req.userId);
    if (!user) return fail(res, 401, "UNAUTHORIZED", "Oturum gerekli");
    const result = await removeMusicQueueItem(roomId, user, req.params.itemId);
    if (!result.ok) {
      return fail(res, 403, "FORBIDDEN", result.error ?? "İşlem başarısız");
    }
    emitChatRoomDjUpdate(roomId);
    return res.status(200).json({ success: true, queue: result.queue });
  },
);

chatRoomsRouter.delete(
  "/rooms/:roomId/music-queue",
  requireAuth,
  async (req, res) => {
    const roomId = req.params.roomId;
    const user = await loadUser(req.userId);
    if (!user) return fail(res, 401, "UNAUTHORIZED", "Oturum gerekli");
    const result = await clearMusicQueue(roomId, user);
    if (!result.ok) {
      return fail(res, 403, "FORBIDDEN", result.error ?? "İşlem başarısız");
    }
    emitChatRoomDjUpdate(roomId);
    return res.status(200).json({ success: true, queue: result.queue });
  },
);

chatRoomsRouter.patch(
  "/rooms/:roomId/music-settings",
  requireAuth,
  async (req, res) => {
    const roomId = req.params.roomId;
    const user = await loadUser(req.userId);
    if (!user) return fail(res, 401, "UNAUTHORIZED", "Oturum gerekli");
    const result = setRoomMusicSettings(roomId, user, {
      musicEnabled:
        typeof req.body?.musicEnabled === "boolean"
          ? req.body.musicEnabled
          : undefined,
      musicRequestCost:
        typeof req.body?.musicRequestCost === "number"
          ? req.body.musicRequestCost
          : undefined,
      maxQueueLength:
        typeof req.body?.maxMusicQueue === "number"
          ? req.body.maxMusicQueue
          : typeof req.body?.maxQueueLength === "number"
            ? req.body.maxQueueLength
            : undefined,
    });
    if (!result.ok) {
      return fail(res, 403, "FORBIDDEN", result.error ?? "Yetki yok");
    }
    return res.status(200).json({
      success: true,
      settings: result.settings,
      ...getDjState(roomId, user),
    });
  },
);

chatRoomsRouter.get("/rooms/:roomId/song-request", optionalAuth, async (req, res) => {
  const roomId = req.params.roomId;
  if (!getChatRoom(roomId)) {
    return fail(res, 404, "NOT_FOUND", "Oda bulunamadı");
  }
  return res.status(200).json({ queue: listMusicQueue(roomId), cost: MUSIC_REQUEST_JETON });
});

chatRoomsRouter.post("/rooms/:roomId/music-queue", requireAuth, async (req, res) => {
  const roomId = req.params.roomId;
  const user = await loadUser(req.userId);
  if (!user) return fail(res, 401, "UNAUTHORIZED", "Oturum gerekli");
  const title = typeof req.body?.title === "string" ? req.body.title : "";
  const youtubeUrl = bodyYoutubeUrl(req.body ?? {});
  const thumbUrl =
    typeof req.body?.thumbUrl === "string" ? req.body.thumbUrl : null;
  const giftTo =
    typeof req.body?.giftTo === "string"
      ? req.body.giftTo
      : typeof req.body?.giftToUsername === "string"
        ? req.body.giftToUsername
        : null;
  const note =
    typeof req.body?.note === "string"
      ? req.body.note
      : typeof req.body?.message === "string"
        ? req.body.message
        : null;
  const priority = req.body?.priority === true;
  const result = await requestMusicQueue(roomId, user, {
    title,
    youtubeUrl,
    thumbUrl,
    giftTo,
    note,
    artist: typeof req.body?.artist === "string" ? req.body.artist : null,
    songName: typeof req.body?.songName === "string" ? req.body.songName : title,
    duration: typeof req.body?.duration === "string" ? req.body.duration : null,
    priority,
  });
  if (!result.ok) {
    const code =
      result.error?.includes("jeton") || (result as { code?: string }).code === "INSUFFICIENT_JETON"
        ? 402
        : 400;
    return fail(res, code, "BAD_REQUEST", result.error ?? "İstek başarısız");
  }
  emitChatRoomDjUpdate(roomId);
  return res.status(200).json({
    success: true,
    item: result.item,
    queue: result.queue,
    newBalance: result.newBalance,
    coinBalance: result.newBalance,
    cost: MUSIC_REQUEST_JETON,
    musicUrl: result.musicUrl,
    playing: result.playing,
  });
});

chatRoomsRouter.post("/rooms/:roomId/dj/:targetUserId", requireAuth, async (req, res) => {
  const user = await loadUser(req.userId);
  if (!user) return fail(res, 401, "UNAUTHORIZED", "Oturum gerekli");
  const result = addRoomDj(req.params.roomId, user, req.params.targetUserId);
  if (!result.ok) return fail(res, 403, "FORBIDDEN", result.error ?? "Yetki yok");
  emitChatRoomDjUpdate(req.params.roomId);
  return ok(res, { djUserIds: result.djUserIds, success: true });
});

chatRoomsRouter.delete("/rooms/:roomId/dj/:targetUserId", requireAuth, async (req, res) => {
  const user = await loadUser(req.userId);
  if (!user) return fail(res, 401, "UNAUTHORIZED", "Oturum gerekli");
  const result = removeRoomDj(req.params.roomId, user, req.params.targetUserId);
  if (!result.ok) return fail(res, 403, "FORBIDDEN", result.error ?? "Yetki yok");
  emitChatRoomDjUpdate(req.params.roomId);
  return ok(res, { djUserIds: result.djUserIds, success: true });
});

async function handleAssignSeat(req: RoomRequest, res: Response) {
  const user = await loadUser(req.userId);
  if (!user) return fail(res, 401, "UNAUTHORIZED", "Oturum gerekli");
  const seatIndex =
    typeof req.body?.seatIndex === "number"
      ? req.body.seatIndex
      : Number(req.body?.seatIndex ?? 0);
  const targetUserId =
    typeof req.body?.userId === "string"
      ? req.body.userId
      : typeof req.body?.targetUserId === "string"
        ? req.body.targetUserId
        : undefined;
  const result = assignSeat(req.params.roomId, user, seatIndex, targetUserId);
  if (!result.ok) {
    return fail(res, 403, "FORBIDDEN", result.error ?? "Koltuk atanamadı");
  }
  emitChatRoomPresence(
    req.params.roomId,
    result.presence as unknown as Record<string, unknown>[],
  );
  return res.status(200).json({ success: true, presence: result.presence });
}

chatRoomsRouter.patch("/rooms/:roomId/seats", requireAuth, async (req: RoomRequest, res) => {
  return handleAssignSeat(req, res);
});

chatRoomsRouter.post("/rooms/:roomId/seats", requireAuth, async (req: RoomRequest, res) => {
  return handleAssignSeat(req, res);
});

/** GET /api/chat/rooms/:roomId/stream — SSE (Flutter birincil kanal) */
chatRoomsRouter.get("/rooms/:roomId/stream", optionalAuth, async (req, res) => {
  const roomId = req.params.roomId;
  if (!getChatRoom(roomId)) {
    return fail(res, 404, "NOT_FOUND", "Oda bulunamadı");
  }

  res.setHeader("Content-Type", "text/event-stream; charset=utf-8");
  res.setHeader("Cache-Control", "no-cache, no-transform");
  res.setHeader("Connection", "keep-alive");
  res.flushHeaders?.();

  const send = (payload: Record<string, unknown>) => {
    res.write(`data: ${JSON.stringify(payload)}\n\n`);
  };

  send({ type: "connected", roomId });

  const msgs = listMessages(roomId);
  let lastId = msgs.length > 0 ? msgs[msgs.length - 1]!.id : "";
  let lastDjSig = "";

  const timer = setInterval(() => {
    try {
      send({ type: "presence", users: listPresence(roomId) });
      const latest = listMessages(roomId);
      for (const m of latest) {
        if (!lastId || m.id > lastId) {
          send({ type: "message", message: m });
          lastId = m.id;
        }
      }
      const dj = getDjState(roomId, null);
      const sig = `${dj.playing}|${dj.musicUrl ?? ""}|${dj.nowPlaying?.id ?? ""}|${dj.musicQueue.length}|${dj.currentPosition ?? 0}`;
      if (sig != lastDjSig) {
        lastDjSig = sig;
        send({
          type: "dj",
          roomId: resolveRoomId(roomId),
          playing: dj.playing,
          isPlaying: dj.playing,
          musicUrl: dj.musicUrl,
          nowPlaying: dj.nowPlaying,
          currentTrack: dj.nowPlaying,
          musicQueue: dj.musicQueue,
          queue: dj.musicQueue,
          queueLength: dj.musicQueue.length,
          currentVideoId: dj.currentVideoId,
          currentPosition: dj.currentPosition,
          trackStartedAt: dj.trackStartedAt,
          positionMs: dj.positionMs,
        });
      }
    } catch {
      /* bağlantı kapanmış olabilir */
    }
  }, 3000);

  req.on("close", () => clearInterval(timer));
});

chatRoomsRouter.get("/rooms/:roomId/messages", optionalAuth, async (req, res) => {
  const roomId = req.params.roomId;
  if (!getChatRoom(roomId)) {
    return fail(res, 404, "NOT_FOUND", "Oda bulunamadı");
  }
  const since = req.query.since as string | undefined;
  const items = listMessages(roomId, since);
  return res.status(200).json({ messages: items, items });
});

chatRoomsRouter.post("/rooms/:roomId/messages", requireAuth, async (req, res) => {
  const roomId = req.params.roomId;
  const user = await loadUser(req.userId);
  if (!user) return fail(res, 401, "UNAUTHORIZED", "Oturum gerekli");
  const content =
    typeof req.body?.content === "string"
      ? req.body.content
      : typeof req.body?.body === "string"
        ? req.body.body
        : typeof req.body?.message === "string"
          ? req.body.message
          : typeof req.body?.text === "string"
            ? req.body.text
            : "";
  const mentionedRaw = req.body?.mentionedUserIds;
  const mentionedUserIds = Array.isArray(mentionedRaw)
    ? mentionedRaw.map((id) => String(id)).filter(Boolean)
    : undefined;
  const row = await addTextMessage(roomId, user, content, mentionedUserIds);
  if (!row) return fail(res, 400, "BAD_REQUEST", "Mesaj gönderilemedi");
  emitChatRoomMessage(resolveRoomId(roomId), row);
  const cmd = content.trim().toLowerCase();
  if (cmd.startsWith("!istek") || cmd.startsWith("/istek")) {
    emitChatRoomDjUpdate(roomId);
  }
  return res.status(200).json({ message: row, success: true });
});

chatRoomsRouter.post("/rooms/:roomId/mentions", requireAuth, async (req, res) => {
  const roomId = req.params.roomId;
  const user = await loadUser(req.userId);
  if (!user) return fail(res, 401, "UNAUTHORIZED", "Oturum gerekli");
  const mentionedRaw = req.body?.mentionedUserIds;
  const mentionedUserIds = Array.isArray(mentionedRaw)
    ? mentionedRaw.map((id) => String(id)).filter(Boolean)
    : [];
  const preview =
    typeof req.body?.preview === "string"
      ? req.body.preview
      : typeof req.body?.content === "string"
        ? req.body.content
        : "";
  await notifyVoiceRoomMentions({
    roomId,
    actor: user,
    mentionedUserIds,
    preview,
  });
  return res.status(200).json({ success: true });
});

chatRoomsRouter.delete("/rooms/:roomId/messages", requireAuth, async (req, res) => {
  const roomId = req.params.roomId;
  const room = getChatRoom(roomId);
  if (!room) return fail(res, 404, "NOT_FOUND", "Oda bulunamadı");
  const user = await loadUser(req.userId);
  if (!user) return fail(res, 401, "UNAUTHORIZED", "Oturum gerekli");
  const priv = roomPrivileges(user, room);
  if (!priv.canModerate && !priv.owner) {
    return fail(res, 403, "FORBIDDEN", "Sohbeti temizlemek için yetkiniz yok");
  }
  clearRoomMessages(roomId);
  return res.status(200).json({ success: true, cleared: true });
});

chatRoomsRouter.get("/rooms/:roomId/presence", optionalAuth, async (req, res) => {
  const roomId = req.params.roomId;
  if (!getChatRoom(roomId)) {
    return fail(res, 404, "NOT_FOUND", "Oda bulunamadı");
  }
  return res.status(200).json({ users: listPresence(roomId) });
});

chatRoomsRouter.post("/rooms/:roomId/presence", requireAuth, async (req, res) => {
  const roomId = req.params.roomId;
  const user = await loadUser(req.userId);
  if (!user) return fail(res, 401, "UNAUTHORIZED", "Oturum gerekli");
  const nickname =
    typeof req.body?.nickname === "string" ? req.body.nickname.trim() : null;
  const result = await joinPresence(roomId, user, { nickname });
  if (!result) return fail(res, 404, "NOT_FOUND", "Oda bulunamadı");
  if ("banned" in result && result.banned) {
    return fail(res, 403, "FORBIDDEN", "Bu odadan yasaklandınız");
  }
  if (result.systemMsg) emitChatRoomMessage(resolveRoomId(roomId), result.systemMsg);
  const joinedRow = result.presence.find((p) => p.id === user.id);
  emitChatRoomPresence(resolveRoomId(roomId), result.presence, {
    joined: joinedRow,
  });
  return res.status(200).json({ users: result.presence });
});

/** PATCH — presence heartbeat (20 sn önerilir) */
chatRoomsRouter.patch("/rooms/:roomId/presence", requireAuth, async (req, res) => {
  const roomId = resolveRoomId(req.params.roomId);
  await presenceHeartbeat(req.userId!, roomId);
  return res.status(200).json({ ok: true, roomId });
});

chatRoomsRouter.delete("/rooms/:roomId/presence", requireAuth, async (req, res) => {
  const roomId = req.params.roomId;
  const userId = req.userId!;
  const result = leavePresence(roomId, userId);
  if (result.systemMsg) emitChatRoomMessage(resolveRoomId(roomId), result.systemMsg);
  emitChatRoomPresence(resolveRoomId(roomId), result.presence, {
    leftUserId: userId,
  });
  return res.status(200).json({ users: result.presence });
});

chatRoomsRouter.get("/rooms/:roomId/dj", optionalAuth, async (req, res) => {
  const roomId = req.params.roomId;
  const user = await loadUser(req.userId);
  return res.status(200).json(getDjState(roomId, user));
});

chatRoomsRouter.post("/rooms/:roomId/dj", requireAuth, async (req, res) => {
  const roomId = req.params.roomId;
  const user = await loadUser(req.userId);
  if (!user) return fail(res, 401, "UNAUTHORIZED", "Oturum gerekli");
  const musicUrl =
    typeof req.body?.musicUrl === "string" ? req.body.musicUrl : null;
  const playing = req.body?.playing === true;
  const state = await setDjMusic(roomId, user, musicUrl, playing);
  if (!state) return fail(res, 403, "FORBIDDEN", "Müzik yetkisi yok");
  emitChatRoomDjUpdate(roomId);
  return res.status(200).json({
    ...getDjState(roomId, user),
    musicUrl: state.musicUrl,
    playing: state.playing,
  });
});

chatRoomsRouter.post("/rooms/:roomId/speak-request", requireAuth, async (req, res) => {
  const roomId = req.params.roomId;
  const userId = req.userId!;
  const pending = requestSpeak(roomId, userId);
  return ok(res, { pending, requested: true });
});

chatRoomsRouter.delete("/rooms/:roomId/speak-request", requireAuth, async (req, res) => {
  const roomId = req.params.roomId;
  const userId = req.userId!;
  const pending = cancelSpeakRequest(roomId, userId);
  return ok(res, { pending, cancelled: true });
});

chatRoomsRouter.get("/rooms/:roomId/speak-requests", requireAuth, async (req, res) => {
  const roomId = req.params.roomId;
  const user = await loadUser(req.userId);
  const room = getChatRoom(roomId);
  if (!room || !user) return fail(res, 404, "NOT_FOUND", "Oda bulunamadı");
  const priv = roomPrivileges(user, room);
  if (!priv.canModerate) return fail(res, 403, "FORBIDDEN", "Yetki yok");
  return ok(res, { userIds: listSpeakRequests(roomId) });
});

chatRoomsRouter.post(
  "/rooms/:roomId/speak-requests/:targetUserId/approve",
  requireAuth,
  async (req, res) => {
    const roomId = req.params.roomId;
    const user = await loadUser(req.userId);
    const room = getChatRoom(roomId);
    if (!room || !user) return fail(res, 404, "NOT_FOUND", "Oda bulunamadı");
    const priv = roomPrivileges(user, room);
    if (!priv.canModerate) return fail(res, 403, "FORBIDDEN", "Yetki yok");
    const approved = approveSpeak(roomId, req.params.targetUserId);
    emitChatRoomPresence(
      resolveRoomId(roomId),
      listPresence(roomId),
      approved ? { joined: approved } : undefined,
    );
    return ok(res, { approved: true });
  },
);

chatRoomsRouter.get("/rooms/:roomId/bans", requireAuth, async (req, res) => {
  const roomId = req.params.roomId;
  const user = await loadUser(req.userId);
  const room = getChatRoom(roomId);
  if (!room || !user) return fail(res, 404, "NOT_FOUND", "Oda bulunamadı");
  const priv = roomPrivileges(user, room);
  if (!priv.canModerate) return fail(res, 403, "FORBIDDEN", "Yetki yok");
  return ok(res, { userIds: listRoomBans(roomId) });
});

chatRoomsRouter.post("/rooms/:roomId/bans/:targetUserId", requireAuth, async (req, res) => {
  const roomId = req.params.roomId;
  const user = await loadUser(req.userId);
  if (!user) return fail(res, 401, "UNAUTHORIZED", "Oturum gerekli");
  const reason =
    typeof req.body?.reason === "string" ? req.body.reason.slice(0, 200) : undefined;
  const result = banRoomUser(roomId, user, req.params.targetUserId, reason);
  if (!result.ok) return fail(res, 403, "FORBIDDEN", result.error);
  if (result.message) emitChatRoomMessage(resolveRoomId(roomId), result.message);
  return ok(res, { banned: true });
});

chatRoomsRouter.delete(
  "/rooms/:roomId/bans/:targetUserId",
  requireAuth,
  async (req, res) => {
    const roomId = req.params.roomId;
    const user = await loadUser(req.userId);
    if (!user) return fail(res, 401, "UNAUTHORIZED", "Oturum gerekli");
    const result = unbanRoomUser(roomId, user, req.params.targetUserId);
    if (!result.ok) return fail(res, 403, "FORBIDDEN", result.error);
    return ok(res, { unbanned: true });
  },
);

chatRoomsRouter.get("/rooms/:roomId/banned-words", optionalAuth, async (req, res) => {
  const roomId = req.params.roomId;
  if (!getChatRoom(roomId)) return fail(res, 404, "NOT_FOUND", "Oda bulunamadı");
  return ok(res, { words: listRoomBannedWords(roomId) });
});

chatRoomsRouter.post("/rooms/:roomId/banned-words", requireAuth, async (req, res) => {
  const roomId = req.params.roomId;
  const user = await loadUser(req.userId);
  if (!user) return fail(res, 401, "UNAUTHORIZED", "Oturum gerekli");
  const word =
    typeof req.body?.word === "string"
      ? req.body.word
      : typeof req.body?.text === "string"
        ? req.body.text
        : "";
  const result = addRoomBannedWord(roomId, user, word);
  if (!result.ok) return fail(res, 403, "FORBIDDEN", result.error);
  return ok(res, { words: result.words });
});

chatRoomsRouter.delete(
  "/rooms/:roomId/banned-words/:word",
  requireAuth,
  async (req, res) => {
    const roomId = req.params.roomId;
    const user = await loadUser(req.userId);
    if (!user) return fail(res, 401, "UNAUTHORIZED", "Oturum gerekli");
    const result = removeRoomBannedWord(
      roomId,
      user,
      decodeURIComponent(req.params.word),
    );
    if (!result.ok) return fail(res, 403, "FORBIDDEN", result.error);
    return ok(res, { words: result.words });
  },
);

chatRoomsRouter.patch("/rooms/:roomId/background", requireAuth, async (req, res) => {
  const roomId = req.params.roomId;
  const user = await loadUser(req.userId);
  if (!user) return fail(res, 401, "UNAUTHORIZED", "Oturum gerekli");
  const url = typeof req.body?.backgroundImage === "string"
    ? req.body.backgroundImage
    : "";
  const room = setRoomBackground(roomId, user, url);
  if (!room) return fail(res, 403, "FORBIDDEN", "Arka plan değiştirilemedi");
  return ok(res, { room });
});

chatRoomsRouter.get("/rooms/:roomId/gifts", async (req, res) => {
  const since = req.query.since as string | undefined;
  return listRoomGiftEvents(req.params.roomId, since, res);
});

chatRoomsRouter.post(
  "/rooms/:roomId/gifts",
  optionalAuth,
  async (req, res) => {
    return sendRoomGift(req.params.roomId, req.body, req.userId, res);
  },
);

/** GET /api/chat/rooms/:roomId/pk-battle */
chatRoomsRouter.get("/rooms/:roomId/pk-battle", optionalAuth, async (req, res) => {
  const battle = await getActiveBattleForRoom(req.params.roomId);
  return ok(res, { battle, pk: battle });
});

/** POST /api/chat/rooms/:roomId/pk-battle */
chatRoomsRouter.post(
  "/rooms/:roomId/pk-battle",
  requireAuth,
  async (req, res) => {
    const roomId = req.params.roomId;
    if (!getChatRoom(roomId)) {
      return fail(res, 404, "NOT_FOUND", "Oda bulunamadı");
    }
    const result = await handleVoiceRoomPkAction(
      roomId,
      req.userId!,
      req.body ?? {},
    );
    if (!result.ok) {
      return fail(res, 400, "BAD_REQUEST", result.error ?? "PK işlemi başarısız");
    }
    const battle = result.battle as Record<string, unknown>;
    const events =
      "events" in result && Array.isArray(result.events)
        ? result.events
        : "event" in result && result.event
          ? [result.event]
          : ["pk:invite"];
    broadcastPkResult(battle, events);
    return ok(res, { battle, pk: battle });
  },
);
