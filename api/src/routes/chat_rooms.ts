import { Router } from "express";
import { optionalAuth } from "../middleware/optionalAuth";
import { requireAuth } from "../middleware/requireAuth";
import { fail, ok } from "../lib/response";
import {
  addTextMessage,
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
  searchYoutube,
  addRoomDj,
  removeRoomDj,
  MUSIC_REQUEST_JETON,
} from "../lib/chatRoomStore";
import { emitChatRoomMessage } from "../socket/giftHub";
import { listRoomGiftEvents, sendRoomGift } from "./gifts";

export const chatRoomsRouter = Router();

/** GET /api/chat/rooms — mobil ham dizi bekler */
chatRoomsRouter.get("/rooms", async (_req, res) => {
  return res.status(200).json(listChatRooms());
});

chatRoomsRouter.post("/rooms/create", requireAuth, async (req, res) => {
  const user = await loadUser(req.userId);
  if (!user) return fail(res, 401, "UNAUTHORIZED", "Oturum açmanız gerekiyor");
  const vip =
    req.body?.isVip === true ||
    req.body?.vip === true ||
    req.body?.roomType === "vip" ||
    req.body?.type === "vip";
  const costRaw =
    req.body?.cost ?? req.body?.jeton ?? req.body?.coins ?? req.body?.amount;
  const cost =
    typeof costRaw === "number"
      ? costRaw
      : typeof costRaw === "string"
        ? Number.parseInt(costRaw, 10)
        : undefined;
  const name =
    typeof req.body?.name === "string"
      ? req.body.name
      : typeof req.body?.nameTr === "string"
        ? req.body.nameTr
        : typeof req.body?.roomName === "string"
          ? req.body.roomName
          : typeof req.body?.title === "string"
            ? req.body.title
            : undefined;
  const result = await createVoiceChatRoom(user, { vip, cost, name });
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

chatRoomsRouter.get("/youtube-search", optionalAuth, async (req, res) => {
  const q = String(req.query.q ?? req.query.query ?? "");
  const items = await searchYoutube(q);
  return res.status(200).json({ items });
});

chatRoomsRouter.get("/rooms/:roomId/music-queue", optionalAuth, async (req, res) => {
  const roomId = req.params.roomId;
  if (!getChatRoom(roomId)) {
    return fail(res, 404, "NOT_FOUND", "Oda bulunamadı");
  }
  return res.status(200).json({ queue: listMusicQueue(roomId), cost: MUSIC_REQUEST_JETON });
});

chatRoomsRouter.post("/rooms/:roomId/song-request", requireAuth, async (req, res) => {
  const roomId = req.params.roomId;
  const user = await loadUser(req.userId);
  if (!user) return fail(res, 401, "UNAUTHORIZED", "Oturum gerekli");
  const title = typeof req.body?.title === "string" ? req.body.title : "";
  const youtubeUrl =
    typeof req.body?.youtubeUrl === "string"
      ? req.body.youtubeUrl
      : typeof req.body?.url === "string"
        ? req.body.url
        : "";
  const thumbUrl =
    typeof req.body?.thumbUrl === "string" ? req.body.thumbUrl : null;
  const result = await requestMusicQueue(roomId, user, { title, youtubeUrl, thumbUrl });
  if (!result.ok) {
    const code = result.error?.includes("jeton") ? 402 : 400;
    return fail(res, code, "BAD_REQUEST", result.error ?? "İstek başarısız");
  }
  return res.status(200).json({
    success: true,
    item: result.item,
    queue: result.queue,
    newBalance: result.newBalance,
    coinBalance: result.newBalance,
    cost: MUSIC_REQUEST_JETON,
  });
});

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
  const youtubeUrl =
    typeof req.body?.youtubeUrl === "string"
      ? req.body.youtubeUrl
      : typeof req.body?.url === "string"
        ? req.body.url
        : "";
  const thumbUrl =
    typeof req.body?.thumbUrl === "string" ? req.body.thumbUrl : null;
  const result = await requestMusicQueue(roomId, user, { title, youtubeUrl, thumbUrl });
  if (!result.ok) {
    const code = result.error?.includes("jeton") ? 402 : 400;
    return fail(res, code, "BAD_REQUEST", result.error ?? "İstek başarısız");
  }
  return res.status(200).json({
    success: true,
    item: result.item,
    queue: result.queue,
    newBalance: result.newBalance,
    coinBalance: result.newBalance,
    cost: MUSIC_REQUEST_JETON,
  });
});

chatRoomsRouter.post("/rooms/:roomId/dj/:targetUserId", requireAuth, async (req, res) => {
  const user = await loadUser(req.userId);
  if (!user) return fail(res, 401, "UNAUTHORIZED", "Oturum gerekli");
  const result = addRoomDj(req.params.roomId, user, req.params.targetUserId);
  if (!result.ok) return fail(res, 403, "FORBIDDEN", result.error ?? "Yetki yok");
  return ok(res, { djUserIds: result.djUserIds });
});

chatRoomsRouter.delete("/rooms/:roomId/dj/:targetUserId", requireAuth, async (req, res) => {
  const user = await loadUser(req.userId);
  if (!user) return fail(res, 401, "UNAUTHORIZED", "Oturum gerekli");
  const result = removeRoomDj(req.params.roomId, user, req.params.targetUserId);
  if (!result.ok) return fail(res, 403, "FORBIDDEN", result.error ?? "Yetki yok");
  return ok(res, { djUserIds: result.djUserIds });
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
  const row = await addTextMessage(roomId, user, content);
  if (!row) return fail(res, 400, "BAD_REQUEST", "Mesaj gönderilemedi");
  emitChatRoomMessage(resolveRoomId(roomId), row);
  return res.status(200).json({ message: row, success: true });
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
  const result = await joinPresence(roomId, user);
  if (!result) return fail(res, 404, "NOT_FOUND", "Oda bulunamadı");
  if ("banned" in result && result.banned) {
    return fail(res, 403, "FORBIDDEN", "Bu odadan yasaklandınız");
  }
  if (result.systemMsg) emitChatRoomMessage(resolveRoomId(roomId), result.systemMsg);
  return res.status(200).json({ users: result.presence });
});

chatRoomsRouter.delete("/rooms/:roomId/presence", requireAuth, async (req, res) => {
  const roomId = req.params.roomId;
  const userId = req.userId!;
  const result = leavePresence(roomId, userId);
  if (result.systemMsg) emitChatRoomMessage(resolveRoomId(roomId), result.systemMsg);
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
  const state = setDjMusic(roomId, user, musicUrl, playing);
  if (!state) return fail(res, 403, "FORBIDDEN", "Müzik yetkisi yok");
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
    approveSpeak(roomId, req.params.targetUserId);
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
