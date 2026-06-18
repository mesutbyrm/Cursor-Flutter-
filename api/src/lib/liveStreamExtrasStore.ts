import { randomUUID } from "node:crypto";

const likeCounts = new Map<string, number>();

export function addStreamLike(streamId: string, amount = 1) {
  const next = (likeCounts.get(streamId) ?? 0) + Math.max(1, amount);
  likeCounts.set(streamId, next);
  return next;
}

export function getStreamLikeCount(streamId: string) {
  return likeCounts.get(streamId) ?? 0;
}

export type PkBattleRow = {
  id: string;
  streamId: string;
  opponentStreamId?: string | null;
  challengerId: string;
  opponentId?: string | null;
  status: "pending" | "active" | "rejected" | "ended";
  leftScore: number;
  rightScore: number;
  winner?: "left" | "right" | "tie" | null;
  createdAt: string;
  endedAt?: string | null;
};

const pkByStream = new Map<string, PkBattleRow>();

function mirrorPkRow(row: PkBattleRow) {
  pkByStream.set(row.streamId, row);
  if (row.opponentStreamId) {
    pkByStream.set(row.opponentStreamId, {
      ...row,
      streamId: row.opponentStreamId,
      opponentStreamId: row.streamId,
      leftScore: row.rightScore,
      rightScore: row.leftScore,
      winner:
        row.winner === "left"
          ? "right"
          : row.winner === "right"
            ? "left"
            : row.winner,
    });
  }
}

function syncPkMirrors(row: PkBattleRow) {
  mirrorPkRow(row);
}

export function getPkBattle(streamId: string) {
  return pkByStream.get(streamId) ?? null;
}

export function handlePkBattleAction(
  streamId: string,
  userId: string,
  input: {
    action: string;
    opponentStreamId?: string;
    opponentId?: string;
    score?: number;
    side?: "left" | "right";
  },
) {
  const action = input.action.trim().toLowerCase();
  const existing = pkByStream.get(streamId);

  if (action === "create") {
    if (existing && existing.status !== "ended") {
      return { ok: false as const, error: "Zaten aktif PK var" };
    }
    const row: PkBattleRow = {
      id: randomUUID(),
      streamId,
      opponentStreamId: input.opponentStreamId ?? null,
      challengerId: userId,
      opponentId: input.opponentId ?? null,
      status: "pending",
      leftScore: 0,
      rightScore: 0,
      createdAt: new Date().toISOString(),
    };
    syncPkMirrors(row);
    return { ok: true as const, battle: row };
  }

  if (!existing) {
    return { ok: false as const, error: "PK bulunamadı" };
  }

  if (action === "accept") {
    existing.status = "active";
    existing.opponentId = userId;
    syncPkMirrors(existing);
    return { ok: true as const, battle: existing };
  }

  if (action === "reject") {
    existing.status = "rejected";
    existing.endedAt = new Date().toISOString();
    syncPkMirrors(existing);
    return { ok: true as const, battle: existing };
  }

  if (action === "score") {
    const bump = Math.max(0, Number(input.score ?? 1));
    if (input.side === "right") existing.rightScore += bump;
    else existing.leftScore += bump;
    syncPkMirrors(existing);
    return { ok: true as const, battle: existing };
  }

  if (action === "end") {
    existing.status = "ended";
    existing.endedAt = new Date().toISOString();
    if (existing.leftScore === existing.rightScore) {
      existing.winner = "tie";
    } else if (existing.leftScore > existing.rightScore) {
      existing.winner = "left";
    } else {
      existing.winner = "right";
    }
    syncPkMirrors(existing);
    return { ok: true as const, battle: existing };
  }

  return { ok: false as const, error: "Geçersiz action" };
}

export type StreamSignalRow = {
  id: string;
  streamId: string;
  fromUserId: string;
  type: string;
  payload: Record<string, unknown>;
  createdAt: string;
};

const signals = new Map<string, StreamSignalRow[]>();

export function pushStreamSignal(
  streamId: string,
  fromUserId: string,
  type: string,
  payload: Record<string, unknown>,
) {
  const row: StreamSignalRow = {
    id: randomUUID(),
    streamId,
    fromUserId,
    type,
    payload,
    createdAt: new Date().toISOString(),
  };
  const list = signals.get(streamId) ?? [];
  list.push(row);
  if (list.length > 500) list.splice(0, list.length - 500);
  signals.set(streamId, list);
  return row;
}

export function listStreamSignals(streamId: string, since?: string) {
  const list = signals.get(streamId) ?? [];
  if (!since) return [...list];
  const t = Date.parse(since);
  if (Number.isNaN(t)) return [...list];
  return list.filter((s) => Date.parse(s.createdAt) > t);
}

export type CoBroadcastInviteRow = {
  id: string;
  streamId: string;
  hostId: string;
  inviteeId: string;
  status: "pending" | "accepted" | "declined";
  createdAt: string;
};

const coInvites = new Map<string, CoBroadcastInviteRow[]>();

export function listCoBroadcastInvites(userId: string) {
  const out: CoBroadcastInviteRow[] = [];
  for (const list of coInvites.values()) {
    for (const row of list) {
      if (row.inviteeId === userId || row.hostId === userId) out.push(row);
    }
  }
  return out.sort((a, b) => b.createdAt.localeCompare(a.createdAt));
}

export function inviteCoBroadcast(
  streamId: string,
  hostId: string,
  inviteeId: string,
) {
  const row: CoBroadcastInviteRow = {
    id: randomUUID(),
    streamId,
    hostId,
    inviteeId,
    status: "pending",
    createdAt: new Date().toISOString(),
  };
  const key = streamId;
  const list = coInvites.get(key) ?? [];
  list.push(row);
  coInvites.set(key, list);
  return row;
}

export function respondCoBroadcastInvite(
  inviteId: string,
  userId: string,
  accept: boolean,
) {
  for (const list of coInvites.values()) {
    const idx = list.findIndex((i) => i.id === inviteId);
    if (idx < 0) continue;
    const row = list[idx]!;
    if (row.inviteeId !== userId) {
      return { ok: false as const, error: "Yetki yok" };
    }
    row.status = accept ? "accepted" : "declined";
    return { ok: true as const, invite: row };
  }
  return { ok: false as const, error: "Davet bulunamadı" };
}

export type FortuneSessionRow = {
  id: string;
  tellerId: string;
  /** TRTC anchor — platform kullanıcı kimliği (falcı profil id'sinden farklı olabilir). */
  tellerUserId: string;
  clientId: string;
  clientName?: string;
  durationMinutes?: number;
  totalJeton?: number;
  fortuneType?: string;
  trtcRoomId: string;
  status: "pending" | "active" | "ended";
  tellerResponse: "pending" | "accepted" | "held" | "rejected";
  timerStartedAt?: string | null;
  lastPingAt?: string | null;
  endedAt?: string | null;
  creditsPerMinute?: number;
  createdAt: string;
  updatedAt: string;
};

const fortuneSessions = new Map<string, FortuneSessionRow>();

export function createFortuneSession(
  tellerId: string,
  clientId: string,
  tellerUserId?: string,
  extras?: {
    clientName?: string;
    durationMinutes?: number;
    totalJeton?: number;
    fortuneType?: string;
    creditsPerMinute?: number;
  },
) {
  const sessionId = `fs-${randomUUID().slice(0, 12)}`;
  const anchorUserId =
    tellerUserId?.trim() || tellerId.trim() || clientId.trim();
  const now = new Date().toISOString();
  const row: FortuneSessionRow = {
    id: sessionId,
    tellerId,
    tellerUserId: anchorUserId,
    clientId,
    clientName: extras?.clientName?.trim() || undefined,
    durationMinutes: extras?.durationMinutes,
    totalJeton: extras?.totalJeton,
    fortuneType: extras?.fortuneType?.trim() || "general",
    creditsPerMinute: extras?.creditsPerMinute,
    trtcRoomId: sessionId,
    status: "pending",
    tellerResponse: "pending",
    timerStartedAt: null,
    lastPingAt: null,
    endedAt: null,
    createdAt: now,
    updatedAt: now,
  };
  fortuneSessions.set(row.id, row);
  return row;
}

export function listIncomingFortuneSessionsForTeller(userId: string) {
  const uid = userId.trim();
  if (!uid) return [];
  return [...fortuneSessions.values()]
    .filter(
      (s) =>
        s.status === "pending" &&
        s.tellerResponse !== "rejected" &&
        (s.tellerUserId === uid || s.tellerId === uid),
    )
    .sort((a, b) => b.createdAt.localeCompare(a.createdAt));
}

export function respondFortuneSession(
  sessionId: string,
  tellerUserId: string,
  action: "accept" | "hold" | "reject",
) {
  const row = fortuneSessions.get(sessionId);
  if (!row) return { ok: false as const, error: "Oturum bulunamadı" };
  if (row.tellerUserId !== tellerUserId && row.tellerId !== tellerUserId) {
    return { ok: false as const, error: "Yetki yok" };
  }
  if (action === "accept") {
    row.tellerResponse = "accepted";
    row.status = "active";
  } else if (action === "hold") {
    row.tellerResponse = "held";
    row.status = "pending";
  } else {
    row.tellerResponse = "rejected";
    row.status = "ended";
    row.endedAt = new Date().toISOString();
  }
  row.updatedAt = new Date().toISOString();
  return { ok: true as const, session: row };
}

export function fortuneSessionRoleForUser(
  session: FortuneSessionRow,
  userId: string,
): "client" | "teller" {
  if (userId === session.tellerUserId || userId === session.tellerId) {
    return "teller";
  }
  return "client";
}

export function getFortuneSession(sessionId: string) {
  return fortuneSessions.get(sessionId) ?? null;
}

/** Üretim uyumu: falcı + danışan oturum listesi. */
export function listFortuneSessionsForUser(userId: string, status?: string) {
  const uid = userId.trim();
  if (!uid) return [];
  const normalizedStatus = status?.trim().toLowerCase();
  return [...fortuneSessions.values()]
    .filter(
      (s) =>
        s.clientId === uid ||
        s.tellerUserId === uid ||
        s.tellerId === uid,
    )
    .filter((s) => !normalizedStatus || s.status === normalizedStatus)
    .sort((a, b) => b.createdAt.localeCompare(a.createdAt));
}

export function listPendingLiveFalRequestsForTeller(userId: string) {
  return listIncomingFortuneSessionsForTeller(userId);
}

export function updateFortuneSessionLifecycle(
  sessionId: string,
  userId: string,
  action: string,
  extras?: {
    minutes?: number;
    durationMinutes?: number;
    creditsPerMinute?: number;
  },
) {
  const row = fortuneSessions.get(sessionId);
  if (!row) return { ok: false as const, error: "Oturum bulunamadı" };
  if (row.clientId !== userId && row.tellerUserId !== userId && row.tellerId !== userId) {
    return { ok: false as const, error: "Yetki yok" };
  }

  const normalized = action.trim().toLowerCase();
  const now = new Date().toISOString();
  if (normalized === "start_timer") {
    row.status = "active";
    row.tellerResponse = "accepted";
    row.timerStartedAt ??= now;
  } else if (normalized === "ping") {
    row.lastPingAt = now;
  } else if (normalized === "extend" || normalized === "teller_add_time") {
    const addMinutes = Math.max(
      0,
      Number(extras?.minutes ?? extras?.durationMinutes ?? 0),
    );
    if (addMinutes > 0) {
      row.durationMinutes = (row.durationMinutes ?? 10) + addMinutes;
    }
  } else if (
    normalized === "end" ||
    normalized === "leave" ||
    normalized === "cancel" ||
    normalized === "complete"
  ) {
    row.status = "ended";
    row.endedAt = now;
    if (normalized === "cancel") row.tellerResponse = "rejected";
  } else {
    return { ok: false as const, error: "Geçersiz action" };
  }

  if (extras?.creditsPerMinute && extras.creditsPerMinute > 0) {
    row.creditsPerMinute = extras.creditsPerMinute;
  }
  row.updatedAt = now;
  return { ok: true as const, session: row };
}

export function fortuneRoomInfoForUser(session: FortuneSessionRow, userId: string) {
  const role = fortuneSessionRoleForUser(session, userId);
  const timerStartedAt = session.timerStartedAt ?? null;
  const elapsedSeconds = timerStartedAt
    ? Math.max(0, Math.floor((Date.now() - Date.parse(timerStartedAt)) / 1000))
    : 0;
  const minutesUsed = Math.floor(elapsedSeconds / 60);
  return {
    id: session.id,
    sessionId: session.id,
    status: session.status,
    tellerResponse: session.tellerResponse,
    roomId: session.trtcRoomId,
    trtcRoomId: session.trtcRoomId,
    maxMinutes: session.durationMinutes ?? 10,
    durationMinutes: session.durationMinutes ?? 10,
    timerStarted: Boolean(timerStartedAt),
    timerStartedAt,
    elapsedSeconds,
    minutesUsed,
    creditsPerMinute: session.creditsPerMinute ?? 10,
    peerId: role === "teller" ? session.clientId : session.tellerUserId,
    isUser: role === "client",
    isClient: role === "client",
    isTeller: role === "teller",
    tellerId: session.tellerId,
    tellerUserId: session.tellerUserId,
    clientId: session.clientId,
    clientName: session.clientName,
    totalJeton: session.totalJeton,
    fortuneType: session.fortuneType,
    createdAt: session.createdAt,
    updatedAt: session.updatedAt,
    endedAt: session.endedAt,
    user: {
      id: userId,
      jetonBalance: 0,
    },
  };
}

export type TellerGiftRow = {
  id: string;
  sessionId: string;
  senderId: string;
  tellerUserId: string;
  amount: number;
  createdAt: string;
};

const tellerGiftsBySession = new Map<string, TellerGiftRow[]>();

export function appendTellerGift(
  sessionId: string,
  senderId: string,
  tellerUserId: string,
  amount: number,
) {
  const key = sessionId.trim();
  const row: TellerGiftRow = {
    id: randomUUID(),
    sessionId: key,
    senderId,
    tellerUserId,
    amount: Math.max(1, Math.round(amount)),
    createdAt: new Date().toISOString(),
  };
  const list = tellerGiftsBySession.get(key) ?? [];
  list.push(row);
  tellerGiftsBySession.set(key, list);
  return row;
}

export type TellerChatRow = {
  id: string;
  sessionId: string;
  senderId: string;
  senderName: string;
  text: string;
  createdAt: string;
};

const tellerChatBySession = new Map<string, TellerChatRow[]>();

export function listTellerChatMessages(sessionId: string) {
  return tellerChatBySession.get(sessionId.trim()) ?? [];
}

export function appendTellerChatMessage(
  sessionId: string,
  senderId: string,
  senderName: string,
  text: string,
) {
  const key = sessionId.trim();
  const row: TellerChatRow = {
    id: randomUUID(),
    sessionId: key,
    senderId,
    senderName: senderName.trim() || "Kullanıcı",
    text: text.trim(),
    createdAt: new Date().toISOString(),
  };
  const list = tellerChatBySession.get(key) ?? [];
  list.push(row);
  tellerChatBySession.set(key, list);
  return row;
}
