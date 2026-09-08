import { Router } from "express";
import {
  addFortuneSessionTip,
  appendTellerChatMessage,
  fortuneSessionRoomPayload,
  getFortuneSession,
  listStreamSignals,
  listTellerChatMessages,
  patchFortuneSessionRoom,
  pushStreamSignal,
  saveFortuneSessionReview,
} from "../lib/liveStreamExtrasStore";
import { fail, ok } from "../lib/response";
import { requireAuth } from "../middleware/requireAuth";

const fortuneRoomSubscribers = new Map<string, Set<import("express").Response>>();

function subscribeFortuneRoomSse(sessionId: string, res: import("express").Response) {
  const key = sessionId.trim();
  let set = fortuneRoomSubscribers.get(key);
  if (!set) {
    set = new Set();
    fortuneRoomSubscribers.set(key, set);
  }
  set.add(res);
}

function unsubscribeFortuneRoomSse(sessionId: string, res: import("express").Response) {
  const key = sessionId.trim();
  const set = fortuneRoomSubscribers.get(key);
  if (!set) return;
  set.delete(res);
  if (set.size === 0) fortuneRoomSubscribers.delete(key);
}

function emitFortuneRoomSse(sessionId: string, event: string, payload: Record<string, unknown>) {
  const set = fortuneRoomSubscribers.get(sessionId.trim());
  if (!set || set.size === 0) return;
  const line = `event: ${event}\ndata: ${JSON.stringify(payload)}\n\n`;
  for (const res of set) {
    try {
      res.write(line);
    } catch {
      set.delete(res);
    }
  }
}

export const fortuneRoomRouter = Router();

fortuneRoomRouter.get("/signal", requireAuth, (req, res) => {
  const sessionId = req.query.sessionId?.toString()?.trim();
  if (!sessionId) {
    return fail(res, 400, "BAD_REQUEST", "sessionId gerekli");
  }
  const since = req.query.since?.toString();
  const signals = listStreamSignals(sessionId, since);
  return ok(res, { signals, items: signals });
});

fortuneRoomRouter.post("/signal", requireAuth, (req, res) => {
  const sessionId = req.body?.sessionId?.toString()?.trim();
  const type = req.body?.type?.toString()?.trim();
  if (!sessionId || !type) {
    return fail(res, 400, "BAD_REQUEST", "sessionId ve type gerekli");
  }
  const session = getFortuneSession(sessionId);
  if (!session) {
    return fail(res, 404, "NOT_FOUND", "Oturum bulunamadı");
  }
  const uid = req.userId!;
  if (session.clientId !== uid && session.tellerUserId !== uid && session.tellerId !== uid) {
    return fail(res, 403, "FORBIDDEN", "Yetki yok");
  }
  const data =
    req.body?.data && typeof req.body.data === "object"
      ? (req.body.data as Record<string, unknown>)
      : {};
  const signal = pushStreamSignal(sessionId, uid, type, {
    ...data,
    receiverId: req.body?.receiverId?.toString(),
  });
  return ok(res, { signal });
});

fortuneRoomRouter.delete("/signal", requireAuth, (req, res) => {
  const sessionId = req.query.sessionId?.toString()?.trim();
  if (!sessionId) {
    return fail(res, 400, "BAD_REQUEST", "sessionId gerekli");
  }
  return ok(res, { cleared: true, sessionId });
});

fortuneRoomRouter.get("/:sessionId", requireAuth, (req, res) => {
  const session = getFortuneSession(req.params.sessionId);
  if (!session) {
    return fail(res, 404, "NOT_FOUND", "Oturum bulunamadı");
  }
  const uid = req.userId!;
  if (session.clientId !== uid && session.tellerUserId !== uid && session.tellerId !== uid) {
    return fail(res, 403, "FORBIDDEN", "Yetki yok");
  }
  return ok(res, fortuneSessionRoomPayload(session, uid));
});

fortuneRoomRouter.patch("/:sessionId", requireAuth, (req, res) => {
  const action = req.body?.action?.toString()?.trim();
  if (!action) {
    return fail(res, 400, "BAD_REQUEST", "action gerekli");
  }
  const minutes = req.body?.minutes != null ? Number(req.body.minutes) : undefined;
  const result = patchFortuneSessionRoom(
    req.params.sessionId,
    req.userId!,
    action,
    { minutes },
  );
  if (!result.ok) {
    return fail(res, 400, "BAD_REQUEST", result.error);
  }
  const payload = fortuneSessionRoomPayload(result.session, req.userId!);
  emitFortuneRoomSse(result.session.id, "timer_started", payload);
  return ok(res, payload);
});

fortuneRoomRouter.get("/:sessionId/messages", requireAuth, (req, res) => {
  const session = getFortuneSession(req.params.sessionId);
  if (!session) {
    return fail(res, 404, "NOT_FOUND", "Oturum bulunamadı");
  }
  const uid = req.userId!;
  if (session.clientId !== uid && session.tellerUserId !== uid && session.tellerId !== uid) {
    return fail(res, 403, "FORBIDDEN", "Yetki yok");
  }
  const after = req.query.after?.toString();
  let messages = listTellerChatMessages(session.id);
  if (after) {
    const t = Date.parse(after);
    if (!Number.isNaN(t)) {
      messages = messages.filter((m) => Date.parse(m.createdAt) > t);
    }
  }
  return ok(res, { messages, items: messages });
});

fortuneRoomRouter.post("/:sessionId/messages", requireAuth, (req, res) => {
  const session = getFortuneSession(req.params.sessionId);
  if (!session) {
    return fail(res, 404, "NOT_FOUND", "Oturum bulunamadı");
  }
  const uid = req.userId!;
  if (session.clientId !== uid && session.tellerUserId !== uid && session.tellerId !== uid) {
    return fail(res, 403, "FORBIDDEN", "Yetki yok");
  }
  const content =
    req.body?.content?.toString()?.trim() ||
    req.body?.text?.toString()?.trim() ||
    req.body?.message?.toString()?.trim();
  if (!content) {
    return fail(res, 400, "BAD_REQUEST", "content gerekli");
  }
  const senderName =
    req.body?.senderName?.toString()?.trim() ||
    (session.clientId === uid ? session.clientName : "Falcı") ||
    "Kullanıcı";
  const message = appendTellerChatMessage(session.id, uid, senderName, content);
  emitFortuneRoomSse(session.id, "message", { message, sessionId: session.id });
  return ok(res, { message });
});

fortuneRoomRouter.post("/:sessionId/tip", requireAuth, (req, res) => {
  const amount = Number(req.body?.amount ?? req.body?.jeton ?? 0);
  const result = addFortuneSessionTip(req.params.sessionId, req.userId!, amount);
  if (!result.ok) {
    return fail(res, 400, "BAD_REQUEST", result.error);
  }
  return ok(res, {
    tipsTotal: result.tipsTotal,
    session: fortuneSessionRoomPayload(result.session, req.userId!),
  });
});

fortuneRoomRouter.post("/:sessionId/review", requireAuth, (req, res) => {
  const rating = Number(req.body?.rating ?? req.body?.stars ?? 0);
  const comment = req.body?.comment?.toString() ?? req.body?.review?.toString();
  const result = saveFortuneSessionReview(
    req.params.sessionId,
    req.userId!,
    rating,
    comment,
  );
  if (!result.ok) {
    return fail(res, 400, "BAD_REQUEST", result.error);
  }
  return ok(res, { review: result.review, success: true });
});

fortuneRoomRouter.get("/:sessionId/stream", requireAuth, async (req, res) => {
  const session = getFortuneSession(req.params.sessionId);
  if (!session) {
    return fail(res, 404, "NOT_FOUND", "Oturum bulunamadı");
  }
  const uid = req.userId!;
  if (session.clientId !== uid && session.tellerUserId !== uid && session.tellerId !== uid) {
    return fail(res, 403, "FORBIDDEN", "Yetki yok");
  }
  const { applySseResponseHeaders } = await import("../lib/sseResponseHeaders.js");
  applySseResponseHeaders(res);
  subscribeFortuneRoomSse(session.id, res);
  res.write(
    `event: connected\ndata: ${JSON.stringify({
      sessionId: session.id,
      status: session.status,
    })}\n\n`,
  );
  const ping = setInterval(() => {
    if (res.writableEnded) {
      clearInterval(ping);
      return;
    }
    res.write(`event: ping\ndata: {"type":"ping"}\n\n`);
  }, 15000);
  req.on("close", () => {
    clearInterval(ping);
    unsubscribeFortuneRoomSse(session.id, res);
    res.end();
  });
});
