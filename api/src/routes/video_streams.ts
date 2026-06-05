import { Router } from "express";
import { prisma } from "../lib/prisma";
import { notifyFollowersLiveStarted } from "../lib/push_events";
import { ok } from "../lib/response";
import { requireAuth } from "../middleware/requireAuth";

const liveStreams = new Map<
  string,
  {
    id: string;
    title: string;
    broadcasterId: string;
    status: string;
    createdAt: string;
  }
>();

export const videoStreamsRouter = Router();

/** GET /api/video-streams — canlı yayın listesi */
videoStreamsRouter.get("/", async (req, res) => {
  const page = Math.max(1, Number(req.query.page ?? 1));
  const limit = Math.min(50, Math.max(1, Number(req.query.limit ?? 30)));
  const all = [...liveStreams.values()].filter((s) => s.status === "live");
  const skip = (page - 1) * limit;
  const slice = all.slice(skip, skip + limit);
  return res.status(200).json({
    streams: slice,
    items: slice,
    data: slice,
    pagination: {
      page,
      limit,
      total: all.length,
      totalPages: Math.max(1, Math.ceil(all.length / limit)),
    },
  });
});

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

  liveStreams.set(streamId, {
    id: streamId,
    title,
    broadcasterId: userId,
    status: "live",
    createdAt: new Date().toISOString(),
  });

  return ok(res, {
    id: streamId,
    streamId,
    title,
    status: "live",
  });
});

/** POST /api/video-streams/:id/end — yayını bitir */
videoStreamsRouter.post("/:id/end", requireAuth, async (req, res) => {
  const streamId = req.params.id;
  const row = liveStreams.get(streamId);
  if (row && row.broadcasterId === req.userId) {
    row.status = "ended";
    liveStreams.set(streamId, row);
  }
  return ok(res, { ended: true, streamId });
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
