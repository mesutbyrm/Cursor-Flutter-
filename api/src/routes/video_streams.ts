import { Router } from "express";
import { prisma } from "../lib/prisma";
import {
  addStreamLike,
  getStreamLikeCount,
  inviteCoBroadcast,
  listStreamSignals,
  pushStreamSignal,
  respondCoBroadcastInvite,
} from "../lib/liveStreamExtrasStore";
import {
  getActiveBattleForStream,
  legacyPkRowFromBattle,
} from "../lib/pkBattleService";
import {
  broadcastPkResult,
  handleLiveStreamPkAction,
} from "./pk_battles";
import {
  addLiveStreamMessage,
  endLiveStream,
  getLiveStream,
  joinLiveStream,
  leaveLiveStream,
  listLiveStreamMessages,
  listLiveStreams,
  upsertLiveStream,
  type LiveStreamRow,
} from "../lib/liveStreamStore";
import { notifyFollowersLiveStarted } from "../lib/push_events";
import { fail, ok } from "../lib/response";
import { optionalAuth } from "../middleware/optionalAuth";
import { requireAuth } from "../middleware/requireAuth";
import {
  emitPkBattleUpdate,
  emitStreamEnded,
  emitStreamMessage,
  emitStreamViewerCount,
} from "../socket/giftHub";

export const videoStreamsRouter = Router();

function mapStream(row: LiveStreamRow) {
  return {
    id: row.id,
    streamId: row.id,
    title: row.title,
    description: row.description,
    category: row.category,
    tags: row.tags,
    status: row.status,
    isLive: row.status === "live",
    viewerCount: row.viewerCount,
    viewers: row.viewerCount,
    watching: row.viewerCount,
    thumbnailUrl: row.thumbnailUrl,
    coverUrl: row.thumbnailUrl,
    broadcastImage: row.thumbnailUrl,
    userId: row.broadcasterId,
    hostUserId: row.broadcasterId,
    streamerId: row.broadcasterId,
    streamerName: row.broadcasterName,
    hostName: row.broadcasterName,
    broadcasterId: row.broadcasterId,
    broadcasterName: row.broadcasterName,
    createdAt: row.createdAt,
    endedAt: row.endedAt,
    likeCount: getStreamLikeCount(row.id),
    user: {
      id: row.broadcasterId,
      name: row.broadcasterName,
      displayName: row.broadcasterName,
    },
  };
}

async function loadUser(userId: string | undefined) {
  if (!userId) return null;
  return prisma.user.findUnique({
    where: { id: userId },
    select: {
      id: true,
      displayName: true,
      username: true,
      avatarUrl: true,
    },
  });
}

/** GET /api/video-streams — canlı yayın listesi */
videoStreamsRouter.get("/", async (req, res) => {
  const page = Math.max(1, Number(req.query.page ?? 1));
  const limit = Math.min(50, Math.max(1, Number(req.query.limit ?? 30)));
  const all = listLiveStreams();
  const skip = (page - 1) * limit;
  const slice = all.slice(skip, skip + limit).map(mapStream);
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

/** GET /api/video-streams/:id — tek yayın */
videoStreamsRouter.get("/:id", optionalAuth, async (req, res) => {
  const id = req.params.id;
  if (id === "gifts") return res.status(404).json({ error: "NOT_FOUND" });
  const row = getLiveStream(id);
  if (!row) return fail(res, 404, "NOT_FOUND", "Yayın bulunamadı");
  return res.status(200).json({ stream: mapStream(row), ...mapStream(row) });
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

  const user = await loadUser(userId);
  const broadcasterName =
    user?.displayName ?? user?.username ?? "Takip ettiğin yayıncı";

  const thumbnailUrl =
    req.body?.thumbnailUrl?.toString()?.trim() ||
    req.body?.coverUrl?.toString()?.trim() ||
    req.body?.broadcastImage?.toString()?.trim() ||
    undefined;

  void notifyFollowersLiveStarted({
    broadcasterId: userId,
    streamId,
    title,
    broadcasterName,
  });

  const row = upsertLiveStream({
    id: streamId,
    title,
    description: req.body?.description?.toString()?.trim() || undefined,
    category: req.body?.category?.toString()?.trim() || undefined,
    tags: Array.isArray(req.body?.tags)
      ? req.body.tags.map((t: unknown) => String(t))
      : undefined,
    broadcasterId: userId,
    broadcasterName,
    thumbnailUrl,
    status: "live",
    viewerCount: 0,
    createdAt: new Date().toISOString(),
  });

  return ok(res, mapStream(row));
});

/** POST /api/video-streams/:id/end — yayını bitir */
videoStreamsRouter.post("/:id/end", requireAuth, async (req, res) => {
  const streamId = req.params.id;
  const row = getLiveStream(streamId);
  if (!row) return fail(res, 404, "NOT_FOUND", "Yayın bulunamadı");
  if (row.broadcasterId !== req.userId) {
    return fail(res, 403, "FORBIDDEN", "Yayını yalnızca yayıncı bitirebilir");
  }
  endLiveStream(streamId);
  emitStreamEnded(streamId, { streamId, reason: "ended" });
  return ok(res, { ended: true, streamId });
});

/** POST /api/video-streams/:id/live-started — mevcut yayın id ile takipçilere push */
videoStreamsRouter.post("/:id/live-started", requireAuth, async (req, res) => {
  const userId = req.userId!;
  const streamId = req.params.id;
  const title = req.body?.title?.toString()?.trim() || "Canlı yayın";

  const user = await loadUser(userId);

  void notifyFollowersLiveStarted({
    broadcasterId: userId,
    streamId,
    title,
    broadcasterName:
      user?.displayName ?? user?.username ?? "Takip ettiğin yayıncı",
  });

  return ok(res, { notified: true, streamId });
});

/** POST /api/video-streams/:id/join — izleyici katılımı */
videoStreamsRouter.post("/:id/join", requireAuth, async (req, res) => {
  const streamId = req.params.id;
  const row = getLiveStream(streamId);
  if (!row || row.status !== "live") {
    return fail(res, 404, "NOT_FOUND", "Yayın aktif değil");
  }
  const count = joinLiveStream(streamId, req.userId!);
  emitStreamViewerCount(streamId, count);
  return ok(res, { viewerCount: count, stream: mapStream(getLiveStream(streamId)!) });
});

/** POST /api/video-streams/:id/leave — izleyici ayrılışı */
videoStreamsRouter.post("/:id/leave", requireAuth, async (req, res) => {
  const streamId = req.params.id;
  const count = leaveLiveStream(streamId, req.userId!);
  emitStreamViewerCount(streamId, count);
  return ok(res, { viewerCount: count });
});

/** GET /api/video-streams/:id/messages */
videoStreamsRouter.get("/:id/messages", optionalAuth, async (req, res) => {
  const streamId = req.params.id;
  if (!getLiveStream(streamId)) {
    return fail(res, 404, "NOT_FOUND", "Yayın bulunamadı");
  }
  const since = req.query.since as string | undefined;
  const items = listLiveStreamMessages(streamId, since);
  return res.status(200).json({ messages: items, items });
});

/** POST /api/video-streams/:id/like — TikTok tarzı kümülatif beğeni */
videoStreamsRouter.post("/:id/like", requireAuth, async (req, res) => {
  const streamId = req.params.id;
  if (!getLiveStream(streamId)) {
    return fail(res, 404, "NOT_FOUND", "Yayın bulunamadı");
  }
  const amount = Math.min(10, Math.max(1, Number(req.body?.count ?? 1)));
  const likeCount = addStreamLike(streamId, amount);
  return ok(res, { likeCount, count: likeCount, success: true });
});

/** POST /api/video-streams/:id/pk-battle */
videoStreamsRouter.post("/:id/pk-battle", requireAuth, async (req, res) => {
  const streamId = req.params.id;
  if (!getLiveStream(streamId)) {
    return fail(res, 404, "NOT_FOUND", "Yayın bulunamadı");
  }
  const result = await handleLiveStreamPkAction(
    streamId,
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
  const legacy = legacyPkRowFromBattle(battle, streamId);
  return ok(res, { battle: legacy, pk: legacy, full: battle });
});

/** GET /api/video-streams/:id/pk-battle */
videoStreamsRouter.get("/:id/pk-battle", optionalAuth, async (req, res) => {
  const streamId = req.params.id;
  const battle = await getActiveBattleForStream(streamId);
  if (!battle) {
    return res.status(200).json({ battle: null, pk: null });
  }
  const legacy = legacyPkRowFromBattle(battle, streamId);
  return res.status(200).json({ battle: legacy, pk: legacy, full: battle });
});

/** GET /api/video-streams/:id/signal — WebRTC polling */
videoStreamsRouter.get("/:id/signal", optionalAuth, async (req, res) => {
  const streamId = req.params.id;
  if (!getLiveStream(streamId)) {
    return fail(res, 404, "NOT_FOUND", "Yayın bulunamadı");
  }
  const since = req.query.since as string | undefined;
  const signals = listStreamSignals(streamId, since);
  return res.status(200).json({ signals, items: signals });
});

/** POST /api/video-streams/:id/signal */
videoStreamsRouter.post("/:id/signal", requireAuth, async (req, res) => {
  const streamId = req.params.id;
  if (!getLiveStream(streamId)) {
    return fail(res, 404, "NOT_FOUND", "Yayın bulunamadı");
  }
  const type = req.body?.type?.toString() ?? "ice";
  const payload =
    req.body?.payload && typeof req.body.payload === "object"
      ? (req.body.payload as Record<string, unknown>)
      : {};
  const row = pushStreamSignal(streamId, req.userId!, type, payload);
  return ok(res, { signal: row });
});

/** POST /api/video-streams/:id/co-broadcast/invite */
videoStreamsRouter.post(
  "/:id/co-broadcast/invite",
  requireAuth,
  async (req, res) => {
    const streamId = req.params.id;
    const row = getLiveStream(streamId);
    if (!row) return fail(res, 404, "NOT_FOUND", "Yayın bulunamadı");
    if (row.broadcasterId !== req.userId) {
      return fail(res, 403, "FORBIDDEN", "Yalnızca yayıncı davet gönderebilir");
    }
    const inviteeId = req.body?.inviteeId?.toString()?.trim();
    if (!inviteeId) {
      return fail(res, 400, "BAD_REQUEST", "inviteeId gerekli");
    }
    const invite = inviteCoBroadcast(streamId, req.userId!, inviteeId);
    return ok(res, { invite });
  },
);

/** POST /api/video-streams/:id/co-broadcast */
videoStreamsRouter.post("/:id/co-broadcast", requireAuth, async (req, res) => {
  const inviteId = req.body?.inviteId?.toString()?.trim();
  if (!inviteId) {
    return fail(res, 400, "BAD_REQUEST", "inviteId gerekli");
  }
  const accept = req.body?.accept !== false;
  const result = respondCoBroadcastInvite(inviteId, req.userId!, accept);
  if (!result.ok) {
    return fail(res, 400, "BAD_REQUEST", result.error ?? "İşlem başarısız");
  }
  return ok(res, { invite: result.invite });
});

/** POST /api/video-streams/:id/messages */
videoStreamsRouter.post("/:id/messages", requireAuth, async (req, res) => {
  const streamId = req.params.id;
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
  const row = addLiveStreamMessage(streamId, {
    id: user.id,
    name: user.displayName ?? user.username ?? "Kullanıcı",
    nickname: user.username ?? undefined,
    image: user.avatarUrl ?? undefined,
  }, content);
  if (!row) return fail(res, 400, "BAD_REQUEST", "Mesaj gönderilemedi");
  emitStreamMessage(streamId, row);
  return res.status(200).json({ message: row, success: true });
});
