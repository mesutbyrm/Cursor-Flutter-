import { Router } from "express";
import { requireAuth } from "../middleware/requireAuth";
import { requireStaff } from "../middleware/requireStaff";
import { ok } from "../lib/response";
import {
  getVoiceRoomSettings,
  settingsPayload,
  updateVoiceRoomSettings,
} from "../lib/voiceRoomSettings";
import { prisma } from "../lib/prisma";

export const voiceRoomSettingsRouter = Router();

/** GET /api/platform/voice-room-settings — herkese açık özet (mobil) */
voiceRoomSettingsRouter.get("/platform/voice-room-settings", async (_req, res) => {
  const s = await getVoiceRoomSettings();
  return ok(res, {
    musicRequestCost: s.musicRequestCost,
    giftReceiverPercent: s.giftReceiverPercent,
    roomOwnerPercent: s.roomOwnerPercent,
    siteCommissionPercent: s.siteCommissionPercent,
    freeRoomMaxUsers: s.freeRoomMaxUsers,
    normalRoomMaxUsers: s.normalRoomMaxUsers,
    vipRoomMaxUsers: s.vipRoomMaxUsers,
  });
});

/** GET /api/platform/commission-rate — üretim uyumluluk */
voiceRoomSettingsRouter.get("/platform/commission-rate", async (_req, res) => {
  const s = await getVoiceRoomSettings();
  return res.status(200).json({
    success: true,
    data: {
      siteCommissionPercent: s.siteCommissionPercent,
      giftReceiverPercent: s.giftReceiverPercent,
      roomOwnerPercent: s.roomOwnerPercent,
    },
  });
});

/** GET /api/admin/voice-room-settings */
voiceRoomSettingsRouter.get(
  "/admin/voice-room-settings",
  requireAuth,
  requireStaff,
  async (_req, res) => {
    const s = await getVoiceRoomSettings();
    return ok(res, settingsPayload(s));
  },
);

/** POST /api/admin/voice-room-settings */
voiceRoomSettingsRouter.post(
  "/admin/voice-room-settings",
  requireAuth,
  requireStaff,
  async (req, res) => {
    const body = req.body ?? {};
    const s = await updateVoiceRoomSettings({
      giftReceiverPercent: body.giftReceiverPercent,
      roomOwnerPercent: body.roomOwnerPercent,
      siteCommissionPercent: body.siteCommissionPercent,
      musicOwnerPercent: body.musicOwnerPercent,
      musicSitePercent: body.musicSitePercent,
      vipMusicOwnerPercent: body.vipMusicOwnerPercent,
      vipMusicSitePercent: body.vipMusicSitePercent,
      musicRequestCost: body.musicRequestCost,
      freeRoomMaxUsers: body.freeRoomMaxUsers,
      normalRoomMaxUsers: body.normalRoomMaxUsers,
      vipRoomMaxUsers: body.vipRoomMaxUsers,
    });
    return ok(res, settingsPayload(s));
  },
);

/** GET /api/admin/voice-room-finance-audit?limit=50 */
voiceRoomSettingsRouter.get(
  "/admin/voice-room-finance-audit",
  requireAuth,
  requireStaff,
  async (req, res) => {
    const limit = Math.min(200, Math.max(1, Number(req.query.limit) || 50));
    const rows = await prisma.voiceRoomFinanceAuditLog.findMany({
      orderBy: { createdAt: "desc" },
      take: limit,
    });
    return ok(res, rows);
  },
);
