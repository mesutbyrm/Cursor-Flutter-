import { prisma } from "./prisma";
import {
  pkCache,
  pkRoomCacheKey,
  pkStreamCacheKey,
} from "./pkCache";

export type PkBattleType = "voice_room" | "live_stream";
export type PkBattleStatus =
  | "pending"
  | "active"
  | "rejected"
  | "ended"
  | "cancelled";

const PK_POINTS_BY_SLUG: Record<string, number> = {
  gul: 1,
  web_rose: 1,
  rose: 1,
  kalp: 10,
  heart: 10,
  ates: 50,
  fire: 50,
  yildiz: 50,
  araba: 1000,
  car: 1000,
  galaksi: 1000,
  yat: 5000,
  yacht: 5000,
  sato: 10000,
  castle: 10000,
  tac: 10000,
  roket: 20000,
  rocket: 20000,
  elmas: 20000,
};

const battleTimers = new Map<string, ReturnType<typeof setTimeout>>();

export function giftToPkPoints(
  slug: string,
  coinPrice: number,
  quantity: number,
): number {
  const unit = PK_POINTS_BY_SLUG[slug.toLowerCase()] ?? coinPrice;
  return Math.max(1, unit) * Math.max(1, quantity);
}

type BattleRow = Awaited<ReturnType<typeof loadBattle>>;

async function loadBattle(id: string) {
  return prisma.pKBattle.findUnique({
    where: { id },
    include: {
      participants: true,
      gifts: { orderBy: { createdAt: "desc" }, take: 50 },
      result: true,
    },
  });
}

function sideFromContext(
  battle: NonNullable<BattleRow>,
  ctx: { roomId?: string; streamId?: string },
): "challenger" | "opponent" | null {
  const roomId = ctx.roomId?.trim();
  const streamId = ctx.streamId?.trim();
  if (battle.battleType === "voice_room" && roomId) {
    if (battle.voiceRoomId === roomId) return "challenger";
    if (battle.opponentVoiceRoomId === roomId) return "opponent";
  }
  if (battle.battleType === "live_stream" && streamId) {
    if (battle.liveStreamId === streamId) return "challenger";
    if (battle.opponentLiveStreamId === streamId) return "opponent";
  }
  return null;
}

export function serializeBattle(battle: NonNullable<BattleRow>) {
  const challenger = battle.participants.find((p) => p.side === "challenger");
  const opponent = battle.participants.find((p) => p.side === "opponent");
  const secondsLeft =
    battle.status === "active" && battle.startTime
      ? Math.max(
          0,
          battle.durationSeconds -
            Math.floor((Date.now() - battle.startTime.getTime()) / 1000),
        )
      : battle.status === "pending"
        ? battle.durationSeconds
        : 0;

  return {
    id: battle.id,
    battleType: battle.battleType,
    voiceRoomId: battle.voiceRoomId,
    opponentVoiceRoomId: battle.opponentVoiceRoomId,
    liveStreamId: battle.liveStreamId,
    opponentLiveStreamId: battle.opponentLiveStreamId,
    challengerId: battle.challengerId,
    opponentId: battle.opponentId,
    status: battle.status,
    startTime: battle.startTime?.toISOString() ?? null,
    endTime: battle.endTime?.toISOString() ?? null,
    winnerId: battle.winnerId,
    challengerScore: battle.challengerScore,
    opponentScore: battle.opponentScore,
    leftScore: battle.challengerScore,
    rightScore: battle.opponentScore,
    durationSeconds: battle.durationSeconds,
    targetScore: battle.targetScore,
    secondsLeft,
    challenger: challenger
      ? {
          userId: challenger.userId,
          roomId: challenger.roomId,
          streamId: challenger.streamId,
          score: challenger.score,
          winStreak: challenger.winStreak,
          displayName: challenger.displayName,
          avatarUrl: challenger.avatarUrl,
        }
      : null,
    opponent: opponent
      ? {
          userId: opponent.userId,
          roomId: opponent.roomId,
          streamId: opponent.streamId,
          score: opponent.score,
          winStreak: opponent.winStreak,
          displayName: opponent.displayName,
          avatarUrl: opponent.avatarUrl,
        }
      : null,
    result: battle.result
      ? {
          winnerId: battle.result.winnerId,
          winnerSide: battle.result.winnerSide,
          challengerFinalScore: battle.result.challengerFinalScore,
          opponentFinalScore: battle.result.opponentFinalScore,
          championBadge: battle.result.championBadge,
        }
      : null,
    recentGifts: battle.gifts.map((g) => ({
      id: g.id,
      senderId: g.senderId,
      senderName: g.senderName,
      side: g.side,
      giftSlug: g.giftSlug,
      giftName: g.giftName,
      quantity: g.quantity,
      points: g.points,
      createdAt: g.createdAt.toISOString(),
    })),
    createdAt: battle.createdAt.toISOString(),
    updatedAt: battle.updatedAt.toISOString(),
  };
}

function cacheBattle(battle: NonNullable<BattleRow>) {
  const payload = serializeBattle(battle);
  if (battle.voiceRoomId) {
    pkCache.set(pkRoomCacheKey(battle.voiceRoomId), battle.id, payload);
  }
  if (battle.opponentVoiceRoomId) {
    pkCache.set(
      pkRoomCacheKey(battle.opponentVoiceRoomId),
      battle.id,
      payload,
    );
  }
  if (battle.liveStreamId) {
    pkCache.set(pkStreamCacheKey(battle.liveStreamId), battle.id, payload);
  }
  if (battle.opponentLiveStreamId) {
    pkCache.set(
      pkStreamCacheKey(battle.opponentLiveStreamId),
      battle.id,
      payload,
    );
  }
  return payload;
}

function clearBattleCache(battle: {
  voiceRoomId?: string | null;
  opponentVoiceRoomId?: string | null;
  liveStreamId?: string | null;
  opponentLiveStreamId?: string | null;
  id: string;
}) {
  if (battle.voiceRoomId) pkCache.delete(pkRoomCacheKey(battle.voiceRoomId));
  if (battle.opponentVoiceRoomId) {
    pkCache.delete(pkRoomCacheKey(battle.opponentVoiceRoomId));
  }
  if (battle.liveStreamId) pkCache.delete(pkStreamCacheKey(battle.liveStreamId));
  if (battle.opponentLiveStreamId) {
    pkCache.delete(pkStreamCacheKey(battle.opponentLiveStreamId));
  }
  pkCache.deleteByBattleId(battle.id);
}

async function resolveWinStreak(userId: string): Promise<number> {
  const last = await prisma.pKResult.findFirst({
    where: { winnerId: userId },
    orderBy: { createdAt: "desc" },
    include: { battle: true },
  });
  if (!last) return 0;
  const prev = await prisma.pKResult.findFirst({
    where: {
      winnerId: userId,
      createdAt: { lt: last.createdAt },
    },
    orderBy: { createdAt: "desc" },
  });
  if (!prev) return 1;
  const gap = last.createdAt.getTime() - prev.createdAt.getTime();
  if (gap > 7 * 24 * 60 * 60 * 1000) return 1;
  return 2;
}

export async function getActiveBattleForRoom(roomId: string) {
  const cached = pkCache.get(pkRoomCacheKey(roomId));
  if (cached) return cached.payload;

  const battle = await prisma.pKBattle.findFirst({
    where: {
      battleType: "voice_room",
      status: { in: ["pending", "active"] },
      OR: [{ voiceRoomId: roomId }, { opponentVoiceRoomId: roomId }],
    },
    include: {
      participants: true,
      gifts: { orderBy: { createdAt: "desc" }, take: 50 },
      result: true,
    },
    orderBy: { createdAt: "desc" },
  });
  if (!battle) return null;
  return cacheBattle(battle);
}

export async function getActiveBattleForStream(streamId: string) {
  const cached = pkCache.get(pkStreamCacheKey(streamId));
  if (cached) return cached.payload;

  const battle = await prisma.pKBattle.findFirst({
    where: {
      battleType: "live_stream",
      status: { in: ["pending", "active"] },
      OR: [{ liveStreamId: streamId }, { opponentLiveStreamId: streamId }],
    },
    include: {
      participants: true,
      gifts: { orderBy: { createdAt: "desc" }, take: 50 },
      result: true,
    },
    orderBy: { createdAt: "desc" },
  });
  if (!battle) return null;
  return cacheBattle(battle);
}

export async function getBattleById(id: string) {
  const battle = await loadBattle(id);
  if (!battle) return null;
  return cacheBattle(battle);
}

export async function listPkHistory(input: {
  userId?: string;
  battleType?: PkBattleType;
  limit?: number;
}) {
  const limit = Math.min(50, Math.max(1, input.limit ?? 20));
  const where = {
    status: "ended",
    ...(input.battleType ? { battleType: input.battleType } : {}),
    ...(input.userId
      ? {
          OR: [
            { challengerId: input.userId },
            { opponentId: input.userId },
            { winnerId: input.userId },
          ],
        }
      : {}),
  };
  const rows = await prisma.pKBattle.findMany({
    where,
    include: {
      participants: true,
      result: true,
      gifts: { orderBy: { createdAt: "desc" }, take: 20 },
    },
    orderBy: { endTime: "desc" },
    take: limit,
  });
  return rows.map((row) => serializeBattle(row));
}

type CreateInviteInput = {
  battleType: PkBattleType;
  challengerId: string;
  voiceRoomId?: string;
  opponentVoiceRoomId?: string;
  liveStreamId?: string;
  opponentLiveStreamId?: string;
  opponentId?: string;
  durationSeconds?: number;
  targetScore?: number;
  challengerDisplay?: { name?: string; avatarUrl?: string };
  opponentDisplay?: { name?: string; avatarUrl?: string };
};

export async function createPkInvite(input: CreateInviteInput) {
  if (input.battleType === "voice_room") {
    if (!input.voiceRoomId || !input.opponentVoiceRoomId) {
      return { ok: false as const, error: "İki oda gerekli" };
    }
    const existing = await getActiveBattleForRoom(input.voiceRoomId);
    if (existing && existing.status !== "ended") {
      return { ok: false as const, error: "Zaten aktif PK var" };
    }
  } else {
    if (!input.liveStreamId || !input.opponentLiveStreamId) {
      return { ok: false as const, error: "İki yayın gerekli" };
    }
    const existing = await getActiveBattleForStream(input.liveStreamId);
    if (existing && existing.status !== "ended") {
      return { ok: false as const, error: "Zaten aktif PK var" };
    }
  }

  const duration = Math.min(900, Math.max(60, input.durationSeconds ?? 300));
  const target = Math.max(1000, input.targetScore ?? 150_000);

  const battle = await prisma.pKBattle.create({
    data: {
      battleType: input.battleType,
      voiceRoomId: input.voiceRoomId ?? null,
      opponentVoiceRoomId: input.opponentVoiceRoomId ?? null,
      liveStreamId: input.liveStreamId ?? null,
      opponentLiveStreamId: input.opponentLiveStreamId ?? null,
      challengerId: input.challengerId,
      opponentId: input.opponentId ?? null,
      status: "pending",
      durationSeconds: duration,
      targetScore: target,
      participants: {
        create: [
          {
            userId: input.challengerId,
            side: "challenger",
            roomId: input.voiceRoomId ?? null,
            streamId: input.liveStreamId ?? null,
            displayName: input.challengerDisplay?.name ?? null,
            avatarUrl: input.challengerDisplay?.avatarUrl ?? null,
            winStreak: await resolveWinStreak(input.challengerId),
          },
          ...(input.opponentId
            ? [
                {
                  userId: input.opponentId,
                  side: "opponent",
                  roomId: input.opponentVoiceRoomId ?? null,
                  streamId: input.opponentLiveStreamId ?? null,
                  displayName: input.opponentDisplay?.name ?? null,
                  avatarUrl: input.opponentDisplay?.avatarUrl ?? null,
                  winStreak: await resolveWinStreak(input.opponentId),
                },
              ]
            : []),
        ],
      },
    },
    include: {
      participants: true,
      gifts: true,
      result: true,
    },
  });

  const payload = cacheBattle(battle);
  return { ok: true as const, battle: payload, event: "pk:invite" as const };
}

export async function acceptPkBattle(battleId: string, opponentUserId: string) {
  const battle = await loadBattle(battleId);
  if (!battle) return { ok: false as const, error: "PK bulunamadı" };
  if (battle.status !== "pending") {
    return { ok: false as const, error: "PK kabul edilemez" };
  }

  const startTime = new Date();
  const endTime = new Date(
    startTime.getTime() + battle.durationSeconds * 1000,
  );

  let opponentParticipant = battle.participants.find((p) => p.side === "opponent");
  if (!opponentParticipant) {
    opponentParticipant = await prisma.pKParticipant.create({
      data: {
        battleId,
        userId: opponentUserId,
        side: "opponent",
        roomId: battle.opponentVoiceRoomId,
        streamId: battle.opponentLiveStreamId,
        winStreak: await resolveWinStreak(opponentUserId),
      },
    });
  }

  const updated = await prisma.pKBattle.update({
    where: { id: battleId },
    data: {
      status: "active",
      opponentId: opponentUserId,
      startTime,
      endTime,
    },
    include: {
      participants: true,
      gifts: { orderBy: { createdAt: "desc" }, take: 50 },
      result: true,
    },
  });

  scheduleBattleEnd(battleId, battle.durationSeconds * 1000);
  const payload = cacheBattle(updated);
  return {
    ok: true as const,
    battle: payload,
    events: ["pk:accept", "pk:start"] as const,
  };
}

export async function rejectPkBattle(battleId: string, userId: string) {
  const battle = await loadBattle(battleId);
  if (!battle) return { ok: false as const, error: "PK bulunamadı" };
  if (battle.status !== "pending") {
    return { ok: false as const, error: "PK reddedilemez" };
  }
  if (
    battle.opponentId &&
    battle.opponentId !== userId &&
    battle.challengerId !== userId
  ) {
    return { ok: false as const, error: "Yetki yok" };
  }

  const updated = await prisma.pKBattle.update({
    where: { id: battleId },
    data: { status: "rejected", endTime: new Date() },
    include: {
      participants: true,
      gifts: true,
      result: true,
    },
  });
  clearBattleTimer(battleId);
  clearBattleCache(updated);
  const payload = serializeBattle(updated);
  return { ok: true as const, battle: payload, event: "pk:reject" as const };
}

function clearBattleTimer(battleId: string) {
  const t = battleTimers.get(battleId);
  if (t) {
    clearTimeout(t);
    battleTimers.delete(battleId);
  }
}

function scheduleBattleEnd(battleId: string, delayMs: number) {
  clearBattleTimer(battleId);
  battleTimers.set(
    battleId,
    setTimeout(() => {
      void endPkBattle(battleId, "timer").catch(console.error);
    }, delayMs),
  );
}

export async function endPkBattle(
  battleId: string,
  reason: "timer" | "manual" = "manual",
) {
  const battle = await loadBattle(battleId);
  if (!battle) return { ok: false as const, error: "PK bulunamadı" };
  if (battle.status !== "active") {
    return { ok: false as const, error: "PK aktif değil" };
  }

  clearBattleTimer(battleId);

  const challengerScore = battle.challengerScore;
  const opponentScore = battle.opponentScore;
  let winnerSide: "challenger" | "opponent" | "tie";
  let winnerId: string | null = null;

  if (challengerScore === opponentScore) {
    winnerSide = "tie";
  } else if (challengerScore > opponentScore) {
    winnerSide = "challenger";
    winnerId = battle.challengerId;
  } else {
    winnerSide = "opponent";
    winnerId = battle.opponentId;
  }

  const updated = await prisma.pKBattle.update({
    where: { id: battleId },
    data: {
      status: "ended",
      endTime: new Date(),
      winnerId,
    },
    include: {
      participants: true,
      gifts: { orderBy: { createdAt: "desc" }, take: 50 },
      result: true,
    },
  });

  await prisma.pKResult.upsert({
    where: { battleId },
    create: {
      battleId,
      winnerId,
      winnerSide,
      challengerFinalScore: challengerScore,
      opponentFinalScore: opponentScore,
      championBadge: winnerId != null,
    },
    update: {
      winnerId,
      winnerSide,
      challengerFinalScore: challengerScore,
      opponentFinalScore: opponentScore,
    },
  });

  const full = await loadBattle(battleId);
  if (!full) return { ok: false as const, error: "PK bulunamadı" };
  const payload = cacheBattle(full);
  return {
    ok: true as const,
    battle: payload,
    reason,
    events: ["pk:end", winnerId ? "pk:winner" : "pk:end"] as const,
  };
}

export async function applyPkGift(input: {
  roomId?: string;
  streamId?: string;
  giftEventId?: string;
  senderId?: string | null;
  senderName: string;
  giftSlug: string;
  giftName?: string;
  quantity: number;
  coinPrice: number;
}) {
  const battleType: PkBattleType | null = input.roomId
    ? "voice_room"
    : input.streamId
      ? "live_stream"
      : null;
  if (!battleType) return null;

  const active =
    battleType === "voice_room" && input.roomId
      ? await getActiveBattleForRoom(input.roomId)
      : input.streamId
        ? await getActiveBattleForStream(input.streamId)
        : null;

  if (!active || active.status !== "active") return null;

  const battle = await loadBattle(active.id as string);
  if (!battle || battle.status !== "active") return null;

  const side = sideFromContext(battle, {
    roomId: input.roomId,
    streamId: input.streamId,
  });
  if (!side) return null;

  const points = giftToPkPoints(
    input.giftSlug,
    input.coinPrice,
    input.quantity,
  );

  const scoreField =
    side === "challenger" ? "challengerScore" : "opponentScore";

  const [updated] = await prisma.$transaction([
    prisma.pKBattle.update({
      where: { id: battle.id },
      data: { [scoreField]: { increment: points } },
    }),
    prisma.pKParticipant.updateMany({
      where: { battleId: battle.id, side },
      data: { score: { increment: points } },
    }),
    prisma.pKGift.create({
      data: {
        battleId: battle.id,
        giftEventId: input.giftEventId ?? null,
        senderId: input.senderId ?? null,
        senderName: input.senderName,
        side,
        giftSlug: input.giftSlug,
        giftName: input.giftName ?? null,
        quantity: input.quantity,
        points,
      },
    }),
  ]);

  const full = await loadBattle(updated.id);
  if (!full) return null;
  const payload = cacheBattle(full);

  return {
    battle: payload,
    gift: {
      side,
      points,
      giftSlug: input.giftSlug,
      giftName: input.giftName,
      quantity: input.quantity,
      senderId: input.senderId,
      senderName: input.senderName,
    },
    events: ["pk:gift", "pk:score-update"] as const,
  };
}

/** Eski video_streams in-memory PK ile uyumluluk */
export function legacyPkRowFromBattle(
  battle: Record<string, unknown>,
  streamId: string,
) {
  const isChallenger = battle.liveStreamId === streamId;
  const leftScore = Number(
    isChallenger ? battle.challengerScore : battle.opponentScore,
  );
  const rightScore = Number(
    isChallenger ? battle.opponentScore : battle.challengerScore,
  );
  const status = String(battle.status ?? "pending");
  let winner: "left" | "right" | "tie" | null = null;
  const winnerSide = battle.result
    ? (battle.result as { winnerSide?: string }).winnerSide
    : null;
  if (status === "ended") {
    if (winnerSide === "tie") winner = "tie";
    else if (winnerSide === "challenger") winner = isChallenger ? "left" : "right";
    else if (winnerSide === "opponent") winner = isChallenger ? "right" : "left";
  }

  return {
    id: battle.id,
    streamId,
    opponentStreamId: isChallenger
      ? battle.opponentLiveStreamId
      : battle.liveStreamId,
    challengerId: battle.challengerId,
    opponentId: battle.opponentId,
    status:
      status === "active"
        ? "active"
        : status === "pending"
          ? "pending"
          : status === "rejected"
            ? "rejected"
            : "ended",
    leftScore,
    rightScore,
    winner,
    createdAt: battle.createdAt,
    endedAt: battle.endTime,
    secondsLeft: battle.secondsLeft,
    targetScore: battle.targetScore,
  };
}
