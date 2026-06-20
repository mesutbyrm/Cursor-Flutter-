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
  trtcRoomId: string;
  status: "pending" | "active" | "ended";
  tellerResponse: "pending" | "accepted" | "held" | "rejected";
  createdAt: string;
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
  },
) {
  const sessionId = `fs-${randomUUID().slice(0, 12)}`;
  const anchorUserId =
    tellerUserId?.trim() || tellerId.trim() || clientId.trim();
  const row: FortuneSessionRow = {
    id: sessionId,
    tellerId,
    tellerUserId: anchorUserId,
    clientId,
    clientName: extras?.clientName?.trim() || undefined,
    durationMinutes: extras?.durationMinutes,
    totalJeton: extras?.totalJeton,
    trtcRoomId: sessionId,
    status: "pending",
    tellerResponse: "pending",
    createdAt: new Date().toISOString(),
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
  }
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
export function listFortuneSessionsForUser(userId: string) {
  const uid = userId.trim();
  if (!uid) return [];
  return [...fortuneSessions.values()]
    .filter(
      (s) =>
        s.clientId === uid ||
        s.tellerUserId === uid ||
        s.tellerId === uid,
    )
    .sort((a, b) => b.createdAt.localeCompare(a.createdAt));
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

export type StreamFortuneRequestRow = {
  id: string;
  streamId: string;
  userId: string;
  username: string;
  displayName: string;
  question: string;
  fortuneType: string;
  priority: "standard" | "priority" | "vip" | "super" | "urgent";
  status: "pending" | "reviewing" | "answered" | "cancelled";
  jetonCost: number;
  createdAt: string;
};

const streamFortuneRequests = new Map<string, StreamFortuneRequestRow>();

function priorityWeight(p: StreamFortuneRequestRow["priority"]) {
  switch (p) {
    case "super":
      return 5;
    case "vip":
      return 4;
    case "urgent":
      return 3;
    case "priority":
      return 2;
    default:
      return 1;
  }
}

export function listStreamFortuneRequests(streamId: string) {
  const id = streamId.trim();
  return [...streamFortuneRequests.values()]
    .filter((r) => r.streamId === id)
    .sort((a, b) => {
      const w = priorityWeight(b.priority) - priorityWeight(a.priority);
      if (w !== 0) return w;
      return a.createdAt.localeCompare(b.createdAt);
    });
}

export function getStreamFortuneRequest(requestId: string) {
  return streamFortuneRequests.get(requestId.trim()) ?? null;
}

export function createStreamFortuneRequest(input: {
  streamId: string;
  userId: string;
  username: string;
  displayName: string;
  question: string;
  fortuneType: string;
  priority: StreamFortuneRequestRow["priority"];
  jetonCost: number;
}) {
  const id = `fr-${randomUUID().slice(0, 12)}`;
  const row: StreamFortuneRequestRow = {
    id,
    streamId: input.streamId.trim(),
    userId: input.userId.trim(),
    username: input.username.trim(),
    displayName: input.displayName.trim(),
    question: input.question.trim(),
    fortuneType: input.fortuneType.trim() || "tarot",
    priority: input.priority,
    status: "pending",
    jetonCost: input.jetonCost,
    createdAt: new Date().toISOString(),
  };
  streamFortuneRequests.set(id, row);
  return row;
}

export function updateStreamFortuneRequestStatus(
  requestId: string,
  streamId: string,
  hostUserId: string,
  status: StreamFortuneRequestRow["status"],
) {
  const row = streamFortuneRequests.get(requestId.trim());
  if (!row || row.streamId !== streamId.trim()) {
    return { ok: false as const, error: "İstek bulunamadı" };
  }
  row.status = status;
  return { ok: true as const, request: row };
}
