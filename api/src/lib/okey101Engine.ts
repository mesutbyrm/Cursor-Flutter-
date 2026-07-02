export type OkeyColor = "red" | "yellow" | "blue" | "black";

export interface OkeyTile {
  id: string;
  color: OkeyColor | "joker";
  value: number;
  isFakeJoker?: boolean;
}

export interface Okey101Player {
  userId: string;
  displayName: string;
  seat: number;
  hand: OkeyTile[];
  opened: boolean;
  penalty: number;
  connected: boolean;
  drewThisTurn?: boolean;
}

export interface Okey101State {
  gameType: "okey101";
  phase: "waiting" | "playing" | "finished";
  status: string;
  openScoreTarget: number;
  maxPlayers: number;
  minPlayers: number;
  indicator: OkeyTile | null;
  okey: OkeyTile | null;
  deck: OkeyTile[];
  discard: OkeyTile[];
  players: Okey101Player[];
  turnIndex: number;
  winnerId?: string;
  winnerName?: string;
  lastMove?: string;
  hostUserId: string;
}

export type Okey101Move =
  | { type: "start" }
  | { type: "draw" }
  | { type: "takeDiscard" }
  | { type: "discard"; tileId: string }
  | { type: "open" };

const COLORS: OkeyColor[] = ["red", "yellow", "blue", "black"];

export function createDeck(): OkeyTile[] {
  const tiles: OkeyTile[] = [];
  for (const color of COLORS) {
    for (let value = 1; value <= 13; value += 1) {
      tiles.push({ id: `${color}-${value}-a`, color, value });
      tiles.push({ id: `${color}-${value}-b`, color, value });
    }
  }
  tiles.push({ id: "joker-fake-a", color: "joker", value: 0, isFakeJoker: true });
  tiles.push({ id: "joker-fake-b", color: "joker", value: 0, isFakeJoker: true });
  return shuffle(tiles);
}

function shuffle<T>(arr: T[]): T[] {
  const copy = [...arr];
  for (let i = copy.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
    [copy[i], copy[j]] = [copy[j], copy[i]];
  }
  return copy;
}

function resolveOkey(indicator: OkeyTile): OkeyTile {
  if (indicator.isFakeJoker || indicator.color === "joker") {
    return { id: "okey-wild", color: "red", value: 1 };
  }
  const next = indicator.value === 13 ? 1 : indicator.value + 1;
  return { id: `okey-${indicator.color}-${next}`, color: indicator.color, value: next };
}

function isWild(tile: OkeyTile, okey: OkeyTile): boolean {
  if (tile.isFakeJoker || tile.color === "joker") return true;
  return tile.color === okey.color && tile.value === okey.value;
}

function tilePoints(tile: OkeyTile, okey: OkeyTile | null): number {
  if (isWild(tile, okey ?? { id: "", color: "red", value: 0 })) return 10;
  return tile.value;
}

function handPoints(hand: OkeyTile[], okey: OkeyTile | null): number {
  return hand.reduce((sum, t) => sum + tilePoints(t, okey), 0);
}

function hasBasicGroup(hand: OkeyTile[], okey: OkeyTile | null): boolean {
  const byColor = new Map<string, number[]>();
  const byValue = new Map<number, number>();
  for (const tile of hand) {
    const color = isWild(tile, okey!) ? "wild" : tile.color;
    const value = isWild(tile, okey!) ? -1 : tile.value;
    if (color !== "wild") {
      const list = byColor.get(color) ?? [];
      list.push(value);
      byColor.set(color, list);
    }
    if (value > 0) {
      byValue.set(value, (byValue.get(value) ?? 0) + 1);
    }
  }
  for (const values of byColor.values()) {
    values.sort((a, b) => a - b);
    let run = 1;
    for (let i = 1; i < values.length; i += 1) {
      if (values[i] === values[i - 1] + 1) {
        run += 1;
        if (run >= 3) return true;
      } else if (values[i] !== values[i - 1]) {
        run = 1;
      }
    }
  }
  for (const count of byValue.values()) {
    if (count >= 3) return true;
  }
  return hand.filter((t) => isWild(t, okey!)).length >= 2;
}

export function createOkey101State(hostUserId: string, hostName: string): Okey101State {
  return {
    gameType: "okey101",
    phase: "waiting",
    status: "waiting",
    openScoreTarget: 101,
    maxPlayers: 4,
    minPlayers: 2,
    indicator: null,
    okey: null,
    deck: [],
    discard: [],
    players: [
      {
        userId: hostUserId,
        displayName: hostName,
        seat: 0,
        hand: [],
        opened: false,
        penalty: 0,
        connected: true,
      },
    ],
    turnIndex: 0,
    hostUserId,
  };
}

export function addPlayer(
  state: Okey101State,
  userId: string,
  displayName: string,
): Okey101State {
  if (state.phase !== "waiting") throw new Error("Oyun başlamış");
  if (state.players.some((p) => p.userId === userId)) return state;
  if (state.players.length >= state.maxPlayers) throw new Error("Oda dolu");
  return {
    ...state,
    players: [
      ...state.players,
      {
        userId,
        displayName,
        seat: state.players.length,
        hand: [],
        opened: false,
        penalty: 0,
        connected: true,
      },
    ],
  };
}

function currentPlayer(state: Okey101State): Okey101Player {
  return state.players[state.turnIndex];
}

function nextTurnIndex(state: Okey101State): number {
  return (state.turnIndex + 1) % state.players.length;
}

export function startGame(state: Okey101State, userId: string): Okey101State {
  if (state.phase !== "waiting") throw new Error("Oyun zaten başladı");
  if (state.players.length < state.minPlayers) {
    throw new Error(`En az ${state.minPlayers} oyuncu gerekli`);
  }
  if (userId !== state.hostUserId) throw new Error("Yalnızca oda sahibi başlatabilir");

  let deck = createDeck();
  const indicator = deck.pop()!;
  const okey = resolveOkey(indicator);

  const players = state.players.map((p, index) => {
    const count = index === 0 ? 15 : 14;
    const hand: OkeyTile[] = [];
    for (let i = 0; i < count; i += 1) {
      const tile = deck.pop();
      if (tile) hand.push(tile);
    }
    return { ...p, hand, opened: false };
  });

  const firstDiscard = deck.pop();
  const discard = firstDiscard ? [firstDiscard] : [];

  return {
    ...state,
    phase: "playing",
    status: "playing",
    indicator,
    okey,
    deck,
    discard,
    players,
    turnIndex: 0,
    lastMove: "Oyun başladı",
  };
}

export function applyMove(
  state: Okey101State,
  userId: string,
  move: Okey101Move,
): Okey101State {
  if (move.type === "start") return startGame(state, userId);
  if (state.phase !== "playing") throw new Error("Oyun aktif değil");

  const playerIndex = state.players.findIndex((p) => p.userId === userId);
  if (playerIndex < 0) throw new Error("Oyuncu değilsiniz");
  if (playerIndex !== state.turnIndex) throw new Error("Sıra sizde değil");

  const player = state.players[playerIndex];
  const okey = state.okey!;

  switch (move.type) {
    case "draw": {
      if (player.drewThisTurn) throw new Error("Bu turda zaten çektiniz");
      if (state.deck.length === 0) throw new Error("Deste bitti");
      const tile = state.deck.pop()!;
      const players = [...state.players];
      players[playerIndex] = {
        ...player,
        hand: [...player.hand, tile],
        drewThisTurn: true,
      };
      return {
        ...state,
        deck: [...state.deck],
        players,
        lastMove: `${player.displayName} desteden çekti`,
      };
    }
    case "takeDiscard": {
      if (player.drewThisTurn) throw new Error("Bu turda zaten çektiniz");
      if (state.discard.length === 0) throw new Error("Atık yok");
      const tile = state.discard.pop()!;
      const players = [...state.players];
      players[playerIndex] = {
        ...player,
        hand: [...player.hand, tile],
        drewThisTurn: true,
      };
      return {
        ...state,
        discard: [...state.discard],
        players,
        lastMove: `${player.displayName} atılan taşı aldı`,
      };
    }
    case "discard": {
      if (!player.drewThisTurn && player.hand.length > 14) {
        throw new Error("Önce taş çekmelisiniz");
      }
      const idx = player.hand.findIndex((t) => t.id === move.tileId);
      if (idx < 0) throw new Error("Taş elinizde yok");
      const tile = player.hand[idx];
      const newHand = player.hand.filter((t) => t.id !== move.tileId);
      const players = [...state.players];
      players[playerIndex] = { ...player, hand: newHand };

      let next: Okey101State = {
        ...state,
        discard: [...state.discard, tile],
        players,
        lastMove: `${player.displayName} taş attı`,
      };

      if (player.opened && newHand.length === 0) {
        next = {
          ...next,
          phase: "finished",
          status: "finished",
          winnerId: userId,
          winnerName: player.displayName,
          turnIndex: playerIndex,
          lastMove: `${player.displayName} okey attı!`,
        };
        return applyPenalties(next, userId);
      }

      const nextIndex = nextTurnIndex(next);
      return {
        ...next,
        turnIndex: nextIndex,
        players: next.players.map((p) => ({ ...p, drewThisTurn: false })),
      };
    }
    case "open": {
      const points = handPoints(player.hand, okey);
      if (points < state.openScoreTarget) {
        throw new Error(`Açmak için en az ${state.openScoreTarget} puan gerekli`);
      }
      if (!hasBasicGroup(player.hand, okey)) {
        throw new Error("Geçerli per/çift yok");
      }
      const players = [...state.players];
      players[playerIndex] = { ...player, opened: true };
      return {
        ...state,
        players,
        lastMove: `${player.displayName} 101 ile açtı (${points} puan)`,
      };
    }
    default:
      throw new Error("Geçersiz hamle");
  }
}

function applyPenalties(state: Okey101State, winnerId: string): Okey101State {
  const okey = state.okey;
  const players = state.players.map((p) => {
    if (p.userId === winnerId) return p;
    const penalty = handPoints(p.hand, okey);
    return { ...p, penalty: p.penalty + penalty };
  });
  return { ...state, players };
}

export function publicView(state: Okey101State, viewerUserId: string) {
  return {
    gameType: state.gameType,
    phase: state.phase,
    status: state.status,
    openScoreTarget: state.openScoreTarget,
    maxPlayers: state.maxPlayers,
    minPlayers: state.minPlayers,
    indicator: state.indicator,
    okey: state.okey,
    deckCount: state.deck.length,
    discardTop: state.discard[state.discard.length - 1] ?? null,
    discardCount: state.discard.length,
    turnUserId: state.players[state.turnIndex]?.userId ?? null,
    turnName: state.players[state.turnIndex]?.displayName ?? null,
    winnerId: state.winnerId,
    winnerName: state.winnerName,
    lastMove: state.lastMove,
    hostUserId: state.hostUserId,
    players: state.players.map((p) => ({
      userId: p.userId,
      displayName: p.displayName,
      seat: p.seat,
      handCount: p.hand.length,
      opened: p.opened,
      penalty: p.penalty,
      connected: p.connected,
      hand: p.userId === viewerUserId ? p.hand : [],
      isMe: p.userId === viewerUserId,
    })),
    myHandPoints:
      state.players.find((p) => p.userId === viewerUserId)?.hand != null
        ? handPoints(
            state.players.find((p) => p.userId === viewerUserId)!.hand,
            state.okey,
          )
        : 0,
  };
}
