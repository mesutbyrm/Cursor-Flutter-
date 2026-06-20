import { Router } from "express";
import { prisma } from "../lib/prisma";
import { getLiveStream } from "../lib/liveStreamStore";
import {
  createStreamFortuneRequest,
  listStreamFortuneRequests,
  updateStreamFortuneRequestStatus,
  getStreamFortuneRequest,
} from "../lib/liveStreamExtrasStore";
import { emitStreamFortuneRequest } from "../socket/giftHub";
import { fail, ok } from "../lib/response";
import { requireAuth } from "../middleware/requireAuth";

/** Legacy alias — `/api/live/fal-request/*` (Flutter spec). */
export const liveFalRequestsRouter = Router();

async function loadUser(userId: string | undefined) {
  if (!userId) return null;
  return prisma.user.findUnique({
    where: { id: userId },
    select: { id: true, username: true, displayName: true, coins: true },
  });
}

function priorityFromBody(body: Record<string, unknown>) {
  const priorityRaw = (body.priority?.toString()?.trim() ?? "standard").toLowerCase();
  return priorityRaw === "priority"
    ? "priority"
    : priorityRaw === "vip"
      ? "vip"
      : priorityRaw === "super"
        ? "super"
        : priorityRaw === "urgent"
          ? "urgent"
          : "standard";
}

function costForPriority(p: string) {
  const costMap: Record<string, number> = {
    standard: 500,
    priority: 1000,
    urgent: 1500,
    vip: 2500,
    super: 2500,
  };
  return costMap[p] ?? 500;
}

liveFalRequestsRouter.post("/live/fal-request/create", requireAuth, async (req, res) => {
  const streamId = req.body?.streamId?.toString()?.trim();
  if (!streamId || !getLiveStream(streamId)) {
    return fail(res, 404, "NOT_FOUND", "Yayın bulunamadı");
  }
  const user = await loadUser(req.userId);
  if (!user) return fail(res, 401, "UNAUTHORIZED", "Oturum gerekli");

  const displayName = req.body?.displayName?.toString()?.trim();
  const question = req.body?.question?.toString()?.trim() ?? "";
  const fortuneType = req.body?.fortuneType?.toString()?.trim() ?? "tarot";
  const priority = priorityFromBody(req.body ?? {});
  const jetonCost = Number(req.body?.jetonCost ?? costForPriority(priority));

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

  emitStreamFortuneRequest(streamId, { type: "fortune_request", request });
  return ok(res, { request, newBalance: updated.coins });
});

liveFalRequestsRouter.post("/live/fal-request/:requestId/update", requireAuth, async (req, res) => {
  const streamId = req.body?.streamId?.toString()?.trim();
  const requestId = req.params.requestId;
  if (!streamId) return fail(res, 400, "BAD_REQUEST", "streamId gerekli");
  const stream = getLiveStream(streamId);
  if (!stream) return fail(res, 404, "NOT_FOUND", "Yayın bulunamadı");
  if (stream.broadcasterId !== req.userId) {
    return fail(res, 403, "FORBIDDEN", "Yetki yok");
  }
  const statusRaw = req.body?.status?.toString()?.trim().toLowerCase() ?? "pending";
  const status =
    statusRaw === "reviewing"
      ? "reviewing"
      : statusRaw === "answered"
        ? "answered"
        : statusRaw === "cancelled"
          ? "cancelled"
          : "pending";
  const result = updateStreamFortuneRequestStatus(requestId, streamId, req.userId!, status);
  if (!result.ok) return fail(res, 400, "BAD_REQUEST", result.error ?? "Hata");
  emitStreamFortuneRequest(streamId, { type: "fortune_request", request: result.request });
  return ok(res, { request: result.request });
});

liveFalRequestsRouter.post("/live/fal-request/:requestId/complete", requireAuth, async (req, res) => {
  req.body = { ...req.body, status: "answered" };
  const streamId = req.body?.streamId?.toString()?.trim();
  if (!streamId) return fail(res, 400, "BAD_REQUEST", "streamId gerekli");
  const stream = getLiveStream(streamId);
  if (!stream) return fail(res, 404, "NOT_FOUND", "Yayın bulunamadı");
  if (stream.broadcasterId !== req.userId) {
    return fail(res, 403, "FORBIDDEN", "Yetki yok");
  }
  const result = updateStreamFortuneRequestStatus(
    req.params.requestId,
    streamId,
    req.userId!,
    "answered",
  );
  if (!result.ok) return fail(res, 400, "BAD_REQUEST", result.error ?? "Hata");
  emitStreamFortuneRequest(streamId, { type: "fortune_request", request: result.request });
  return ok(res, { request: result.request });
});

liveFalRequestsRouter.get("/live/fal-requests", requireAuth, async (req, res) => {
  const streamId = req.query.streamId?.toString()?.trim();
  if (!streamId) return fail(res, 400, "BAD_REQUEST", "streamId gerekli");
  const requests = listStreamFortuneRequests(streamId);
  return ok(res, { requests, items: requests });
});

liveFalRequestsRouter.get("/live/fal-request/:requestId", requireAuth, async (req, res) => {
  const row = getStreamFortuneRequest(req.params.requestId);
  if (!row) return fail(res, 404, "NOT_FOUND", "İstek bulunamadı");
  return ok(res, { request: row });
});
