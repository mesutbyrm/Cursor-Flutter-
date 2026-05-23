import { Router } from "express";
import { prisma } from "../lib/prisma";
import { notifyFollowersLiveStarted } from "../lib/push_events";
import { ok } from "../lib/response";
import { requireAuth } from "../middleware/requireAuth";

export const videoStreamsRouter = Router();

/**
 * POST /api/video-streams — yayın başladı (self-hosted API).
 * canlifal.com: aynı mantığı site backend'inde çağırın (docs/CANLIFAL_COM_PUSH.md).
 */
videoStreamsRouter.post("/", requireAuth, async (req, res) => {
  const userId = req.userId!;
  const title =
    req.body?.title?.toString()?.trim() ||
    req.body?.name?.toString()?.trim() ||
    "Canlı yayın";
  const streamId =
    req.body?.id?.toString()?.trim() ||
    req.body?.streamId?.toString()?.trim() ||
    `stream-${userId}-${Date.now()}`;

  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { displayName: true, username: true },
  });
  const broadcasterName =
    user?.displayName ?? user?.username ?? "Takip ettiğin yayıncı";

  void notifyFollowersLiveStarted({
    broadcasterId: userId,
    streamId,
    title,
    broadcasterName,
  });

  return ok(res, {
    id: streamId,
    streamId,
    title,
    status: "live",
  });
});

/** POST /api/video-streams/:id/live-started — mevcut yayın id ile takipçilere push */
videoStreamsRouter.post("/:id/live-started", requireAuth, async (req, res) => {
  const userId = req.userId!;
  const streamId = req.params.id;
  const title = req.body?.title?.toString()?.trim() || "Canlı yayın";

  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { displayName: true, username: true },
  });

  void notifyFollowersLiveStarted({
    broadcasterId: userId,
    streamId,
    title,
    broadcasterName:
      user?.displayName ?? user?.username ?? "Takip ettiğin yayıncı",
  });

  return ok(res, { notified: true, streamId });
});
