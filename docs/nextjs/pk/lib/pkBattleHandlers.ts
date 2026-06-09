/**
 * Oda / yayın PK action handler'ları — api/src/routes/pk_battles.ts ile senkron.
 * Web reposunda: getChatRoom / getLiveStream mevcut helper'larınızla bağlayın.
 */
import {
  acceptPkBattle,
  createPkInvite,
  endPkBattle,
  getActiveBattleForRoom,
  getActiveBattleForStream,
  rejectPkBattle,
} from "./pkBattleService";
import { emitPkBattleEvent, emitPkBattleUpdate } from "@/lib/socket/giftHub";

// TODO: canlifal.com chat room / live stream lookup
declare function getChatRoom(id: string): {
  ownerId?: string;
  nameTr?: string;
  owner?: { displayName?: string; image?: string };
} | null;
declare function getLiveStream(id: string): {
  broadcasterId?: string;
  title?: string;
} | null;

export async function handleVoiceRoomPkAction(
  roomId: string,
  userId: string,
  body: Record<string, unknown>,
) {
  const action = String(body.action ?? "create").trim().toLowerCase();
  const opponentRoomId =
    body.opponentRoomId?.toString() ?? body.opponentVoiceRoomId?.toString();
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
      challengerDisplay: { name: stream?.title },
      opponentDisplay: { name: opp?.title },
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
