import { Router } from "express";
import { prisma } from "../lib/prisma";
import { ok } from "../lib/response";
import { requireAuth } from "../middleware/requireAuth";

export const devicesRouter = Router();

/** POST /api/devices/fcm — FCM token kaydı */
devicesRouter.post("/fcm", requireAuth, async (req, res) => {
  const userId = req.userId!;
  const token =
    (req.body?.token as string | undefined) ??
    (req.body?.fcmToken as string | undefined);
  if (!token || typeof token !== "string" || token.length < 20) {
    return res.status(400).json({
      success: false,
      error: "Geçersiz FCM token",
    });
  }
  const platformRaw =
    (req.body?.platform as string | undefined)?.trim() || "unknown";
  const provider = (req.body?.provider as string | undefined)?.trim();
  const platform = provider ? `${provider}:${platformRaw}` : platformRaw;

  await prisma.devicePushToken.upsert({
    where: { token },
    create: { userId, token, platform },
    update: { userId, platform, updatedAt: new Date() },
  });

  return ok(res, { registered: true });
});
