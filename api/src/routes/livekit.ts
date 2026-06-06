import { Router } from "express";
import { AccessToken } from "livekit-server-sdk";
import { z } from "zod";
import { fail, ok } from "../lib/response";
import { requireAuth } from "../middleware/requireAuth";

export const livekitRouter = Router();

const tokenSchema = z.object({
  roomId: z.string().min(1).max(128),
  roomName: z.string().min(1).max(128).optional(),
});

/** POST /api/livekit/token — sesli oda için LiveKit JWT */
livekitRouter.post("/token", requireAuth, async (req, res) => {
  const parsed = tokenSchema.safeParse(req.body);
  if (!parsed.success) {
    return fail(res, 400, "VALIDATION_ERROR", "Geçersiz istek", parsed.error.flatten());
  }

  const apiKey = process.env.LIVEKIT_API_KEY?.trim();
  const apiSecret = process.env.LIVEKIT_API_SECRET?.trim();
  const url = process.env.LIVEKIT_URL?.trim();

  if (!apiKey || !apiSecret || !url) {
    return fail(
      res,
      503,
      "LIVEKIT_DISABLED",
      "LiveKit yapılandırılmamış (LIVEKIT_API_KEY, LIVEKIT_API_SECRET, LIVEKIT_URL)",
    );
  }

  const roomName = parsed.data.roomName?.trim() || parsed.data.roomId.trim();
  const identity = req.userId!;

  const at = new AccessToken(apiKey, apiSecret, {
    identity,
    ttl: "6h",
  });
  at.addGrant({
    roomJoin: true,
    room: roomName,
    canPublish: true,
    canSubscribe: true,
    canPublishData: true,
  });

  const token = await at.toJwt();

  return ok(res, {
    token,
    url,
    roomName,
    identity,
  });
});
