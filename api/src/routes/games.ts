import { Router } from "express";
import { randomUUID } from "node:crypto";
import { requireAuth } from "../middleware/requireAuth";
import { ok, fail } from "../lib/response";
import {
  addPlayer,
  applyMove,
  createOkey101State,
  publicView,
  type Okey101Move,
  type Okey101State,
} from "../lib/okey101Engine";

interface GameRoom {
  id: string;
  title: string;
  gameId: string;
  hostUserId: string;
  status: string;
  maxPlayers: number;
  jetonCost: number;
  createdAt: Date;
  chat: { userId: string; text: string; at: string }[];
  okey101?: Okey101State;
}

const rooms = new Map<string, GameRoom>();

function isOkey101(gameId: string): boolean {
  const id = gameId.toLowerCase();
  return id === "okey101" || id === "okey-101" || id.includes("okey101");
}

function roomPayload(room: GameRoom) {
  return {
    id: room.id,
    roomId: room.id,
    title: room.title,
    gameId: room.gameId,
    slug: room.gameId,
    status: room.status,
    maxPlayers: room.maxPlayers,
    playerCount: room.okey101?.players.length ?? 0,
    jetonCost: room.jetonCost,
  };
}

function roomState(room: GameRoom, viewerUserId: string) {
  const base = roomPayload(room);
  if (room.okey101) {
    return {
      ...base,
      gameType: "okey101",
      turn: room.okey101.players[room.okey101.turnIndex]?.userId,
      currentTurn: room.okey101.players[room.okey101.turnIndex]?.userId,
      result: room.okey101.winnerName,
      winner: room.okey101.winnerId,
      okey101: publicView(room.okey101, viewerUserId),
      chat: room.chat.map((c) => ({
        text: c.text,
        content: c.text,
        message: c.text,
        userId: c.userId,
      })),
    };
  }
  return {
    ...base,
    chat: room.chat.map((c) => ({ text: c.text, content: c.text })),
  };
}

function syncRoomStatus(room: GameRoom) {
  if (room.okey101) {
    room.status = room.okey101.status;
  }
}

export const gamesRouter = Router();

gamesRouter.get("/games", (_req, res) => {
  const items = [
    {
      id: "okey101",
      slug: "okey101",
      title: "Okey 101",
      name: "Okey 101",
      type: "multiplayer",
      description: "4 oyunculu 101 puanlı Türk okey — site API uyumlu",
      maxPlayers: 4,
      route: "/games-hub/okey101",
    },
    {
      id: "okey",
      slug: "okey",
      title: "Okey",
      type: "multiplayer",
      maxPlayers: 4,
    },
    {
      id: "tavla",
      slug: "tavla",
      title: "Tavla",
      type: "multiplayer",
    },
    {
      id: "xox",
      slug: "xox",
      title: "XOX",
      type: "multiplayer",
    },
  ];
  return ok(res, { items, games: items });
});

gamesRouter.get("/games/rooms", requireAuth, (_req, res) => {
  const open = [...rooms.values()]
    .filter((r) => r.status === "waiting" || r.status === "playing")
    .map(roomPayload);
  return ok(res, { rooms: open, items: open });
});

gamesRouter.post("/games/rooms", requireAuth, (req, res) => {
  const userId = req.userId!;
  const body = req.body ?? {};
  const gameId = String(body.gameId ?? body.slug ?? body.type ?? "okey101");
  const title = String(body.title ?? "Okey 101 Odası");
  const displayName = String(body.displayName ?? body.nickname ?? "Oyuncu");
  const jetonCost = Number(body.jetonCost ?? 0);

  const id = randomUUID().slice(0, 12);
  const room: GameRoom = {
    id,
    title,
    gameId,
    hostUserId: userId,
    status: "waiting",
    maxPlayers: isOkey101(gameId) ? 4 : 2,
    jetonCost,
    createdAt: new Date(),
    chat: [],
  };

  if (isOkey101(gameId)) {
    room.okey101 = createOkey101State(userId, displayName);
  }

  rooms.set(id, room);
  return ok(res, { room: roomPayload(room) }, 201);
});

gamesRouter.post("/games/auto-match", requireAuth, (req, res) => {
  const userId = req.userId!;
  const body = req.body ?? {};
  const gameId = String(body.gameId ?? body.slug ?? "okey101");
  const displayName = String(body.displayName ?? "Oyuncu");

  const waiting = [...rooms.values()].find(
    (r) =>
      r.gameId === gameId &&
      r.status === "waiting" &&
      (r.okey101?.players.length ?? 0) < r.maxPlayers &&
      !r.okey101?.players.some((p) => p.userId === userId),
  );

  if (waiting) {
    if (waiting.okey101) {
      waiting.okey101 = addPlayer(waiting.okey101, userId, displayName);
      syncRoomStatus(waiting);
    }
    return ok(res, { room: roomPayload(waiting) });
  }

  const id = randomUUID().slice(0, 12);
  const room: GameRoom = {
    id,
    title: isOkey101(gameId) ? "Okey 101 — Otomatik" : "Oyun odası",
    gameId,
    hostUserId: userId,
    status: "waiting",
    maxPlayers: isOkey101(gameId) ? 4 : 2,
    jetonCost: 0,
    createdAt: new Date(),
    chat: [],
  };
  if (isOkey101(gameId)) {
    room.okey101 = createOkey101State(userId, displayName);
  }
  rooms.set(id, room);
  return ok(res, { room: roomPayload(room) }, 201);
});

gamesRouter.post("/games/room/:roomId/join", requireAuth, (req, res) => {
  const userId = req.userId!;
  const room = rooms.get(req.params.roomId);
  if (!room) return fail(res, 404, "NOT_FOUND", "Oda bulunamadı");

  const displayName = String(req.body?.displayName ?? req.body?.nickname ?? "Oyuncu");
  if (room.okey101) {
    try {
      room.okey101 = addPlayer(room.okey101, userId, displayName);
      syncRoomStatus(room);
    } catch (e) {
      const msg = e instanceof Error ? e.message : "Katılınamadı";
      return fail(res, 400, "JOIN_FAILED", msg);
    }
  }
  return ok(res, { room: roomPayload(room) });
});

gamesRouter.post("/games/room/:roomId", requireAuth, (req, res) => {
  const userId = req.userId!;
  const room = rooms.get(req.params.roomId);
  if (!room) return fail(res, 404, "NOT_FOUND", "Oda bulunamadı");

  const action = String(req.body?.action ?? "state");
  if (action === "state") {
    return ok(res, roomState(room, userId));
  }

  if (action === "move") {
    const moveBody = (req.body?.move ?? req.body) as Record<string, unknown>;
    const type = String(moveBody.type ?? "draw");

    if (!room.okey101) {
      return ok(res, roomState(room, userId));
    }

    try {
      let move: Okey101Move;
      switch (type) {
        case "start":
          move = { type: "start" };
          break;
        case "draw":
          move = { type: "draw" };
          break;
        case "takeDiscard":
          move = { type: "takeDiscard" };
          break;
        case "discard":
          move = { type: "discard", tileId: String(moveBody.tileId ?? "") };
          break;
        case "open":
          move = { type: "open" };
          break;
        default:
          return fail(res, 400, "INVALID_MOVE", "Geçersiz hamle");
      }
      room.okey101 = applyMove(room.okey101, userId, move);
      syncRoomStatus(room);
      return ok(res, roomState(room, userId));
    } catch (e) {
      const msg = e instanceof Error ? e.message : "Hamle reddedildi";
      return fail(res, 400, "MOVE_REJECTED", msg);
    }
  }

  return fail(res, 400, "INVALID_ACTION", "Bilinmeyen action");
});

gamesRouter.post("/games/room/:roomId/chat", requireAuth, (req, res) => {
  const userId = req.userId!;
  const room = rooms.get(req.params.roomId);
  if (!room) return fail(res, 404, "NOT_FOUND", "Oda bulunamadı");

  const text = String(
    req.body?.message ?? req.body?.text ?? req.body?.content ?? "",
  ).trim();
  if (text.length > 0) {
    room.chat.push({ userId, text, at: new Date().toISOString() });
    if (room.chat.length > 100) room.chat.shift();
  }
  return ok(res, { ok: true });
});

gamesRouter.post("/games/leaderboard", requireAuth, (_req, res) => {
  return ok(res, { items: [], leaderboard: [] });
});

gamesRouter.get("/games/history", requireAuth, (_req, res) => {
  return ok(res, { items: [] });
});

gamesRouter.get("/games/profile", requireAuth, (_req, res) => {
  return ok(res, { items: [] });
});

gamesRouter.post("/games/mini-scores", requireAuth, (req, res) => {
  return ok(res, { ok: true, score: req.body?.score ?? 0 });
});

gamesRouter.get("/games/mini-scores", requireAuth, (_req, res) => {
  return ok(res, { items: [] });
});

gamesRouter.get("/tournaments", requireAuth, (_req, res) => {
  return ok(res, { items: [] });
});

gamesRouter.post("/tournaments/join", requireAuth, (_req, res) => {
  return ok(res, { ok: true });
});
