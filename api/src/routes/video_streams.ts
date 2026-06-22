import { Router } from "express";
import { prisma } from "../lib/prisma";
import {
  addStreamLike,
  getStreamLikeCount,
  inviteCoBroadcast,
  listStreamSignals,
  pushStreamSignal,
  respondCoBroadcastInvite,
  createStreamFortuneRequest,
  listStreamFortuneRequests,
  updateStreamFortuneRequestStatus,
  listCoBroadcastJoinRequests,
  listCoBroadcasters,
  requestCoBroadcastJoin,
  respondCoBroadcastJoin,
  muteStreamViewer,
  unmuteStreamViewer,
  banStreamViewer,
  unbanStreamViewer,
  addStreamModerator,
  removeStreamModerator,
  listStreamModerators,
  getPkBattle,
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
  emitStreamFortuneRequest,
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
      coins: true,
    },
  });
}

/** GET /api/video-streams — canlı yayın listesi */
videoStreamsRouter.get("/", async (req, res) => {
  const page = Math.max(1, Number(req.query.page ?? 1));
  const limit = Math.min(50, Math.max(1, Number(req.query.limit ?? 30)));
  const category = req.query.category?.toString()?.trim();
  let all = listLiveStreams();
  if (category) {
    all = all.filter((s) => (s.category ?? "").toLowerCase() === category.toLowerCase());
  }
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

/** GET /api/video-streams/:id/co-broadcast */
videoStreamsRouter.get("/:id/co-broadcast", requireAuth, async (req, res) => {
  const streamId = req.params.id;
  if (!getLiveStream(streamId)) {
    return fail(res, 404, "NOT_FOUND", "Yayın bulunamadı");
  }
  return ok(res, {
    coBroadcasters: listCoBroadcasters(streamId),
    joinRequests: listCoBroadcastJoinRequests(streamId),
    pendingRequests: listCoBroadcastJoinRequests(streamId),
  });
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
  const streamId = req.params.id;
  const stream = getLiveStream(streamId);
  if (!stream) return fail(res, 404, "NOT_FOUND", "Yayın bulunamadı");

  const action = req.body?.action?.toString()?.trim().toLowerCase() ?? "";
  const userId = req.body?.userId?.toString()?.trim();

  if (action === "request") {
    const user = await loadUser(req.userId);
    const row = requestCoBroadcastJoin(
      streamId,
      req.userId!,
      user?.displayName ?? user?.username ?? "İzleyici",
    );
    return ok(res, { request: row, joinRequest: row });
  }

  if (action === "approve" || action === "accept") {
    if (stream.broadcasterId !== req.userId) {
      return fail(res, 403, "FORBIDDEN", "Yalnızca yayıncı onaylayabilir");
    }
    if (!userId) {
      return fail(res, 400, "BAD_REQUEST", "userId gerekli");
    }
    const result = respondCoBroadcastJoin(streamId, req.userId!, userId, true);
    if (!result.ok) {
      return fail(res, 400, "BAD_REQUEST", result.error ?? "Onaylanamadı");
    }
    return ok(res, { request: result.request, coBroadcaster: result.request });
  }

  if (action === "reject" || action === "decline") {
    if (stream.broadcasterId !== req.userId) {
      return fail(res, 403, "FORBIDDEN", "Yalnızca yayıncı reddedebilir");
    }
    if (!userId) {
      return fail(res, 400, "BAD_REQUEST", "userId gerekli");
    }
    const result = respondCoBroadcastJoin(streamId, req.userId!, userId, false);
    if (!result.ok) {
      return fail(res, 400, "BAD_REQUEST", result.error ?? "Reddedilemedi");
    }
    return ok(res, { request: result.request });
  }

  const inviteId = req.body?.inviteId?.toString()?.trim();
  if (!inviteId) {
    return fail(res, 400, "BAD_REQUEST", "inviteId veya action gerekli");
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

/** GET /api/video-streams/:id/fortune-requests */
videoStreamsRouter.get("/:id/fortune-requests", requireAuth, async (req, res) => {
  const streamId = req.params.id;
  if (!getLiveStream(streamId)) {
    return fail(res, 404, "NOT_FOUND", "Yayın bulunamadı");
  }
  const requests = listStreamFortuneRequests(streamId);
  return ok(res, { requests, items: requests });
});

/** POST /api/video-streams/:id/fortune-requests */
videoStreamsRouter.post("/:id/fortune-requests", requireAuth, async (req, res) => {
  const streamId = req.params.id;
  const stream = getLiveStream(streamId);
  if (!stream) return fail(res, 404, "NOT_FOUND", "Yayın bulunamadı");

  const user = await loadUser(req.userId);
  if (!user) return fail(res, 401, "UNAUTHORIZED", "Oturum gerekli");

  const displayName =
    req.body?.displayName?.toString()?.trim() ||
    req.body?.display_name?.toString()?.trim();
  const question = req.body?.question?.toString()?.trim() ?? "";
  const fortuneType =
    req.body?.fortuneType?.toString()?.trim() ||
    req.body?.type?.toString()?.trim() ||
    "tarot";
  const priorityRaw = (req.body?.priority?.toString()?.trim() ?? "standard").toLowerCase();
  const priority =
    priorityRaw === "priority" || priorityRaw === "oncelikli"
      ? "priority"
      : priorityRaw === "vip"
        ? "vip"
        : priorityRaw === "super" || priorityRaw === "superfal"
          ? "super"
          : priorityRaw === "urgent" || priorityRaw === "acil"
            ? "urgent"
            : "standard";

  const costMap: Record<string, number> = {
    standard: 500,
    priority: 1000,
    urgent: 1500,
    vip: 2500,
    super: 2500,
  };
  const jetonCost = Number(req.body?.jetonCost ?? costMap[priority] ?? 500);

  if (!displayName || displayName.length < 2) {
    return fail(res, 400, "VALIDATION_ERROR", "Görünecek isim gerekli");
  }
  if (question.length < 5) {
    return fail(res, 400, "VALIDATION_ERROR", "Fal sorusu çok kısa");
  }

  if (user.coins < jetonCost) {
    return fail(res, 402, "INSUFFICIENT_COINS", "Yetersiz jeton");
  }

  const updated = await prisma.user.update({
    where: { id: user.id },
    data: { coins: { decrement: jetonCost } },
  });

  const request = createStreamFortuneRequest({
    streamId,
    userId: user.id,
    username: user.username ?? user.displayName ?? "user",
    displayName,
    question,
    fortuneType,
    priority,
    jetonCost,
  });

  emitStreamFortuneRequest(streamId, {
    type: "fortune_request",
    request,
  });

  return ok(res, {
    request,
    newBalance: updated.coins,
    coinBalance: updated.coins,
  });
});

/** PATCH /api/video-streams/:id/fortune-requests/:requestId */
videoStreamsRouter.patch(
  "/:id/fortune-requests/:requestId",
  requireAuth,
  async (req, res) => {
    const streamId = req.params.id;
    const stream = getLiveStream(streamId);
    if (!stream) return fail(res, 404, "NOT_FOUND", "Yayın bulunamadı");
    if (stream.broadcasterId !== req.userId) {
      return fail(res, 403, "FORBIDDEN", "Yalnızca yayıncı güncelleyebilir");
    }
    const statusRaw = req.body?.status?.toString()?.trim().toLowerCase() ?? "pending";
    const status =
      statusRaw === "reviewing" || statusRaw === "inceleniyor"
        ? "reviewing"
        : statusRaw === "answered" || statusRaw === "completed"
          ? "answered"
          : statusRaw === "cancelled"
            ? "cancelled"
            : "pending";

    const result = updateStreamFortuneRequestStatus(
      req.params.requestId,
      streamId,
      req.userId!,
      status,
    );
    if (!result.ok) {
      return fail(res, 400, "BAD_REQUEST", result.error ?? "Güncellenemedi");
    }
    emitStreamFortuneRequest(streamId, {
      type: "fortune_request",
      request: result.request,
    });
    return ok(res, { request: result.request });
  },
);

/** POST /api/video-streams/:id/mute */
videoStreamsRouter.post("/:id/mute", requireAuth, async (req, res) => {
  const streamId = req.params.id;
  if (!getLiveStream(streamId)) {
    return fail(res, 404, "NOT_FOUND", "Yayın bulunamadı");
  }
  const viewerId =
    req.body?.viewerId?.toString()?.trim() ||
    req.body?.userId?.toString()?.trim();
  if (!viewerId) {
    return fail(res, 400, "BAD_REQUEST", "viewerId gerekli");
  }
  muteStreamViewer(streamId, viewerId);
  return ok(res, { muted: true, viewerId });
});

videoStreamsRouter.delete("/:id/mute", requireAuth, async (req, res) => {
  const streamId = req.params.id;
  const viewerId =
    req.body?.viewerId?.toString()?.trim() ||
    req.query.userId?.toString()?.trim() ||
    req.query.viewerId?.toString()?.trim();
  if (!viewerId) {
    return fail(res, 400, "BAD_REQUEST", "viewerId gerekli");
  }
  unmuteStreamViewer(streamId, viewerId);
  return ok(res, { muted: false, viewerId });
});

/** POST /api/video-streams/:id/ban */
videoStreamsRouter.post("/:id/ban", requireAuth, async (req, res) => {
  const streamId = req.params.id;
  if (!getLiveStream(streamId)) {
    return fail(res, 404, "NOT_FOUND", "Yayın bulunamadı");
  }
  const userId = req.body?.userId?.toString()?.trim();
  if (!userId) {
    return fail(res, 400, "BAD_REQUEST", "userId gerekli");
  }
  banStreamViewer(streamId, userId);
  return ok(res, { banned: true, userId });
});

videoStreamsRouter.delete("/:id/ban", requireAuth, async (req, res) => {
  const streamId = req.params.id;
  const userId =
    req.body?.userId?.toString()?.trim() ||
    req.query.userId?.toString()?.trim();
  if (!userId) {
    return fail(res, 400, "BAD_REQUEST", "userId gerekli");
  }
  unbanStreamViewer(streamId, userId);
  return ok(res, { banned: false, userId });
});

videoStreamsRouter.get("/:id/moderators", requireAuth, async (req, res) => {
  const streamId = req.params.id;
  if (!getLiveStream(streamId)) {
    return fail(res, 404, "NOT_FOUND", "Yayın bulunamadı");
  }
  const mods = listStreamModerators(streamId);
  return ok(res, {
    moderators: mods.map((id) => ({ userId: id })),
    items: mods.map((id) => ({ userId: id })),
  });
});

videoStreamsRouter.post("/:id/moderators", requireAuth, async (req, res) => {
  const streamId = req.params.id;
  const userId = req.body?.userId?.toString()?.trim();
  if (!userId) {
    return fail(res, 400, "BAD_REQUEST", "userId gerekli");
  }
  addStreamModerator(streamId, userId);
  return ok(res, { added: true, userId });
});

videoStreamsRouter.delete("/:id/moderators", requireAuth, async (req, res) => {
  const streamId = req.params.id;
  const userId =
    req.body?.userId?.toString()?.trim() ||
    req.query.userId?.toString()?.trim();
  if (!userId) {
    return fail(res, 400, "BAD_REQUEST", "userId gerekli");
  }
  removeStreamModerator(streamId, userId);
  return ok(res, { removed: true, userId });
});

videoStreamsRouter.post("/:id/moderator", requireAuth, async (req, res) => {
  const streamId = req.params.id;
  const userId = req.body?.userId?.toString()?.trim();
  if (!userId) {
    return fail(res, 400, "BAD_REQUEST", "userId gerekli");
  }
  addStreamModerator(streamId, userId);
  return ok(res, { added: true, userId });
});

videoStreamsRouter.delete("/:id/moderator", requireAuth, async (req, res) => {
  const streamId = req.params.id;
  const userId = req.body?.userId?.toString()?.trim();
  if (!userId) {
    return fail(res, 400, "BAD_REQUEST", "userId gerekli");
  }
  removeStreamModerator(streamId, userId);
  return ok(res, { removed: true, userId });
});

/** GET /api/video-streams/:id/stream — SSE */
videoStreamsRouter.get("/:id/stream", optionalAuth, async (req, res) => {
  const streamId = req.params.id;
  const stream = getLiveStream(streamId);
  if (!stream) {
    return fail(res, 404, "NOT_FOUND", "Yayın bulunamadı");
  }

  res.setHeader("Content-Type", "text/event-stream; charset=utf-8");
  res.setHeader("Cache-Control", "no-cache, no-transform");
  res.setHeader("Connection", "keep-alive");
  res.flushHeaders?.();

  const send = (payload: Record<string, unknown>) => {
    res.write(`data: ${JSON.stringify(payload)}\n\n`);
  };

  send({ type: "connected", streamId });

  let lastMsgId = "";
  const msgs = listLiveStreamMessages(streamId);
  if (msgs.length > 0) lastMsgId = msgs[msgs.length - 1]!.id;
  let lastViewer = stream.viewerCount;
  let lastFortuneSig = "";
  let lastPkSig = "";
  let ended = stream.status !== "live";

  const timer = setInterval(() => {
    try {
      const row = getLiveStream(streamId);
      if (!row) {
        send({ type: "streamEnded", streamId });
        return;
      }
      if (row.viewerCount !== lastViewer) {
        lastViewer = row.viewerCount;
        send({ type: "viewerCount", streamId, viewerCount: lastViewer });
      }
      const latest = listLiveStreamMessages(streamId);
      for (const m of latest) {
        if (!lastMsgId || m.id > lastMsgId) {
          send({ type: "streamMessage", message: m });
          lastMsgId = m.id;
        }
      }
      const fortune = listStreamFortuneRequests(streamId);
      const fSig = fortune.map((f) => `${f.id}:${f.status}`).join("|");
      if (fSig !== lastFortuneSig) {
        lastFortuneSig = fSig;
        for (const request of fortune) {
          send({ type: "fortune_request", streamId, request });
        }
      }
      const pk = getPkBattle(streamId);
      const pkSig = pk
        ? `${pk.id}:${pk.status}:${pk.leftScore}:${pk.rightScore}`
        : "";
      if (pkSig !== lastPkSig) {
        lastPkSig = pkSig;
        if (pk) send({ type: "pk", streamId, data: pk, battle: pk });
      }
      if (!ended && row.status !== "live") {
        ended = true;
        send({ type: "streamEnded", streamId });
      }
      res.write(`: heartbeat\n\n`);
    } catch {
      /* bağlantı kapalı olabilir */
    }
  }, 2500);

  req.on("close", () => clearInterval(timer));
});
