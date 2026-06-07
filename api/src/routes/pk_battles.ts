import { Router } from "express";
import { z } from "zod";
import { getChatRoom, loadUser } from "../lib/chatRoomStore";
import { getLiveStream } from "../lib/liveStreamStore";
import {
  acceptPkBattle,
  createPkInvite,
  endPkBattle,
  getActiveBattleForRoom,
  getActiveBattleForStream,
  getBattleById,
  listPkHistory,
  rejectPkBattle,
} from "../lib/pkBattleService";
import { fail, ok } from "../lib/response";
import { optionalAuth } from "../middleware/optionalAuth";
import { requireAuth } from "../middleware/requireAuth";
import {
  emitPkBattleEvent,
  emitPkBattleUpdate,
} from "../socket/giftHub";

export const pkBattlesRouter = Router();

const inviteSchema = z.object({
  battleType: z.enum(["voice_room", "live_stream"]),
  voiceRoomId: z.string().optional(),
  opponentVoiceRoomId: z.string().optional(),
  liveStreamId: z.string().optional(),
  opponentLiveStreamId: z.string().optional(),
  opponentId: z.string().optional(),
  durationSeconds: z.coerce.number().int().min(60).max(900).optional(),
  targetScore: z.coerce.number().int().min(1000).optional(),
});

/** POST /api/pk/battles — PK daveti */
pkBattlesRouter.post("/battles", requireAuth, async (req, res) => {
  const parsed = inviteSchema.safeParse(req.body);
  if (!parsed.success) {
    return fail(res, 400, "VALIDATION_ERROR", "Geçersiz PK isteği", parsed.error.flatten());
  }
  const data = parsed.data;

  const user = await loadUser(req.userId);
  if (!user) return fail(res, 401, "UNAUTHORIZED", "Oturum gerekli");
  const result = await createPkInvite({
    ...data,
    challengerId: user.id,
    challengerDisplay: {
      name: user.displayName ?? user.username ?? undefined,
      avatarUrl: user.avatarUrl ?? undefined,
    },
  });

  if (!result.ok) {
    return fail(res, 400, "BAD_REQUEST", result.error);
  }

  emitPkBattleEvent(result.battle, "pk:invite");
  return ok(res, { battle: result.battle, pk: result.battle });
});

/** POST /api/pk/battles/:id/accept */
pkBattlesRouter.post("/battles/:id/accept", requireAuth, async (req, res) => {
  const result = await acceptPkBattle(req.params.id, req.userId!);
  if (!result.ok) return fail(res, 400, "BAD_REQUEST", result.error);
  for (const event of result.events) {
    emitPkBattleEvent(result.battle, event);
  }
  return ok(res, { battle: result.battle, pk: result.battle });
});

/** POST /api/pk/battles/:id/reject */
pkBattlesRouter.post("/battles/:id/reject", requireAuth, async (req, res) => {
  const result = await rejectPkBattle(req.params.id, req.userId!);
  if (!result.ok) return fail(res, 400, "BAD_REQUEST", result.error);
  emitPkBattleEvent(result.battle, result.event);
  return ok(res, { battle: result.battle, pk: result.battle });
});

/** POST /api/pk/battles/:id/end */
pkBattlesRouter.post("/battles/:id/end", requireAuth, async (req, res) => {
  const battle = await getBattleById(req.params.id);
  if (!battle) return fail(res, 404, "NOT_FOUND", "PK bulunamadı");
  if (
    battle.challengerId !== req.userId &&
    battle.opponentId !== req.userId
  ) {
    return fail(res, 403, "FORBIDDEN", "Yetki yok");
  }
  const result = await endPkBattle(req.params.id, "manual");
  if (!result.ok) return fail(res, 400, "BAD_REQUEST", result.error);
  for (const event of result.events) {
    emitPkBattleEvent(result.battle, event);
  }
  return ok(res, { battle: result.battle, pk: result.battle });
});

/** GET /api/pk/battles/:id */
pkBattlesRouter.get("/battles/:id", optionalAuth, async (req, res) => {
  const battle = await getBattleById(req.params.id);
  if (!battle) return fail(res, 404, "NOT_FOUND", "PK bulunamadı");
  return ok(res, { battle, pk: battle });
});

/** GET /api/pk/history */
pkBattlesRouter.get("/history", optionalAuth, async (req, res) => {
  const battleType =
    req.query.battleType === "voice_room" || req.query.battleType === "live_stream"
      ? req.query.battleType
      : undefined;
  const userId =
    (req.query.userId as string | undefined) ?? req.userId ?? undefined;
  const limit = Number(req.query.limit ?? 20);
  const items = await listPkHistory({ userId, battleType, limit });
  return ok(res, { items, history: items });
});

/** POST /api/chat/rooms/:roomId/pk-battle — sesli oda PK (web/Flutter uyumlu) */
export async function handleVoiceRoomPkAction(
  roomId: string,
  userId: string,
  body: Record<string, unknown>,
) {
  const action = String(body.action ?? "create").trim().toLowerCase();
  const opponentRoomId = body.opponentRoomId?.toString() ?? body.opponentVoiceRoomId?.toString();
  const battleId = body.battleId?.toString();

  if (action === "create") {
    if (!opponentRoomId) {
      return { ok: false as const, error: "Karşı oda gerekli" };
    }
    const room = getChatRoom(roomId);
    const opp = getChatRoom(opponentRoomId);
    return createPkInvite({
      battleType: "voice_room",
      challengerId: userId,
      voiceRoomId: roomId,
      opponentVoiceRoomId: opponentRoomId,
      opponentId: opp?.ownerId ?? body.opponentId?.toString(),
      durationSeconds: Number(body.durationSeconds ?? 300),
      targetScore: Number(body.targetScore ?? 150_000),
      challengerDisplay: {
        name: room?.owner?.displayName ?? room?.nameTr,
        avatarUrl: room?.owner?.image ?? undefined,
      },
      opponentDisplay: {
        name: opp?.owner?.displayName ?? opp?.nameTr,
        avatarUrl: opp?.owner?.image ?? undefined,
      },
    });
  }

  if (action === "accept" && battleId) {
    return acceptPkBattle(battleId, userId);
  }
  if (action === "reject" && battleId) {
    return rejectPkBattle(battleId, userId);
  }
  if (action === "end" && battleId) {
    return endPkBattle(battleId, "manual");
  }

  const active = await getActiveBattleForRoom(roomId);
  if (!active) return { ok: false as const, error: "PK bulunamadı" };
  if (action === "accept") return acceptPkBattle(active.id as string, userId);
  if (action === "reject") return rejectPkBattle(active.id as string, userId);
  if (action === "end") return endPkBattle(active.id as string, "manual");

  return { ok: false as const, error: "Geçersiz action" };
}

/** POST /api/video-streams/:id/pk-battle — canlı yayın PK */
export async function handleLiveStreamPkAction(
  streamId: string,
  userId: string,
  body: Record<string, unknown>,
) {
  const action = String(body.action ?? "create").trim().toLowerCase();
  const opponentStreamId =
    body.opponentStreamId?.toString() ?? body.opponentLiveStreamId?.toString();
  const battleId = body.battleId?.toString();

  if (action === "create") {
    if (!opponentStreamId) {
      return { ok: false as const, error: "Karşı yayın gerekli" };
    }
    const stream = getLiveStream(streamId);
    const opp = getLiveStream(opponentStreamId);
    return createPkInvite({
      battleType: "live_stream",
      challengerId: userId,
      liveStreamId: streamId,
      opponentLiveStreamId: opponentStreamId,
      opponentId: opp?.broadcasterId ?? body.opponentId?.toString(),
      durationSeconds: Number(body.durationSeconds ?? 300),
      targetScore: Number(body.targetScore ?? 150_000),
      challengerDisplay: {
        name: stream?.title,
      },
      opponentDisplay: {
        name: opp?.title,
      },
    });
  }

  if (action === "accept" && battleId) {
    return acceptPkBattle(battleId, userId);
  }
  if (action === "reject" && battleId) {
    return rejectPkBattle(battleId, userId);
  }
  if (action === "end" && battleId) {
    return endPkBattle(battleId, "manual");
  }

  const active = await getActiveBattleForStream(streamId);
  if (!active) return { ok: false as const, error: "PK bulunamadı" };
  if (action === "accept") return acceptPkBattle(active.id as string, userId);
  if (action === "reject") return rejectPkBattle(active.id as string, userId);
  if (action === "end") return endPkBattle(active.id as string, "manual");

  return { ok: false as const, error: "Geçersiz action" };
}

export function broadcastPkResult(
  battle: Record<string, unknown>,
  events: readonly string[],
) {
  for (const event of events) {
    emitPkBattleEvent(battle, event);
  }
  if (battle.battleType === "live_stream") {
    const streamId = battle.liveStreamId;
    const oppId = battle.opponentLiveStreamId;
    if (typeof streamId === "string") {
      emitPkBattleUpdate(streamId, battle);
    }
    if (typeof oppId === "string") {
      emitPkBattleUpdate(oppId, battle);
    }
  }
}
