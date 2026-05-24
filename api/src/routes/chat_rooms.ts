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
  requestSpeak,
  roomPrivileges,
  setDjMusic,
  setRoomBackground,
  unbanRoomUser,
} from "../lib/chatRoomStore";
import { emitChatRoomMessage } from "../socket/giftHub";
import { listRoomGiftEvents, sendRoomGift } from "./gifts";

export const chatRoomsRouter = Router();

/** GET /api/chat/rooms — mobil ham dizi bekler */
chatRoomsRouter.get("/rooms", async (_req, res) => {
  return res.status(200).json(listChatRooms());
});

chatRoomsRouter.get("/rooms/backgrounds", async (_req, res) => {
  return ok(res, { backgrounds: listSiteBackgrounds() });
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
  emitChatRoomMessage(roomId, row);
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
  if (result.systemMsg) emitChatRoomMessage(roomId, result.systemMsg);
  return res.status(200).json({ users: result.presence });
});

chatRoomsRouter.delete("/rooms/:roomId/presence", requireAuth, async (req, res) => {
  const roomId = req.params.roomId;
  const userId = req.userId!;
  const result = leavePresence(roomId, userId);
  if (result.systemMsg) emitChatRoomMessage(roomId, result.systemMsg);
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
  if (result.message) emitChatRoomMessage(roomId, result.message);
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
