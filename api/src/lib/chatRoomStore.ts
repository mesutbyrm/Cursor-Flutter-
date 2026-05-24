import { randomUUID } from "node:crypto";
import type { User } from "@prisma/client";
import { prisma } from "./prisma";

export type ChatRoomUser = {
  id: string;
  name: string;
  nickname?: string | null;
  image?: string | null;
  chatRole?: string;
  roleSymbol?: string | null;
  membership?: string | null;
};

export type ChatRoomMessageRow = {
  id: string;
  content: string;
  createdAt: string;
  user?: ChatRoomUser;
};

export type ChatPresenceRow = ChatRoomUser & {
  seatIndex?: number | null;
  isSpeaking?: boolean;
  joinedAt: number;
};

export type ChatRoomRow = {
  id: string;
  slug: string;
  nameTr: string;
  descTr?: string;
  icon?: string;
  onlineCount: number;
  userCount: number;
  backgroundImage?: string;
  ownerId?: string;
  owner?: { id: string; displayName?: string | null; image?: string | null };
  activeDjId?: string | null;
  djUserIds: string[];
  recentUsers: { image?: string | null }[];
  rules?: string;
};

const SITE_BACKGROUNDS = [
  "https://canlifal.com/images/voice-bg-1.jpg",
  "https://canlifal.com/images/voice-bg-2.jpg",
  "https://canlifal.com/apple-touch-icon.png",
];

const rooms: ChatRoomRow[] = [
  {
    id: "room-1",
    slug: "genel",
    nameTr: "Genel Sohbet",
    descTr:
      "Oda kuralları: Saygılı olun, spam yapmayın, reklam yasak. Yönetici kararları geçerlidir.",
    icon: "🎤",
    onlineCount: 0,
    userCount: 0,
    backgroundImage: SITE_BACKGROUNDS[0],
    ownerId: "system",
    owner: { id: "system", displayName: "Canlifal", image: "https://canlifal.com/favicon.ico" },
    activeDjId: null,
    djUserIds: [],
    recentUsers: [],
    rules:
      "1. Saygılı dil kullanın.\n2. Spam ve reklam yasaktır.\n3. Yetkililerin uyarılarına uyun.",
  },
];

const messages = new Map<string, ChatRoomMessageRow[]>();
const presence = new Map<string, Map<string, ChatPresenceRow>>();
const speakRequests = new Map<string, Set<string>>();
const djByRoom = new Map<
  string,
  { activeDjId: string | null; musicUrl: string | null; playing: boolean }
>();

function roomMap(roomId: string) {
  let m = presence.get(roomId);
  if (!m) {
    m = new Map();
    presence.set(roomId, m);
  }
  return m;
}

export function listSiteBackgrounds() {
  return SITE_BACKGROUNDS;
}

export function listChatRooms(): ChatRoomRow[] {
  return rooms.map((r) => {
    const p = roomMap(r.id);
    const users = [...p.values()];
    const recent = users
      .slice(-12)
      .map((u) => ({ image: u.image }))
      .reverse();
    return {
      ...r,
      onlineCount: users.length,
      userCount: users.length,
      recentUsers: recent,
    };
  });
}

export function getChatRoom(roomId: string) {
  return listChatRooms().find((r) => r.id === roomId || r.slug === roomId);
}

export function listMessages(roomId: string, since?: string) {
  const all = messages.get(roomId) ?? [];
  if (!since) return all.slice(-120);
  const t = Date.parse(since);
  if (Number.isNaN(t)) return all.slice(-120);
  return all.filter((m) => Date.parse(m.createdAt) > t);
}

function pushMessage(roomId: string, row: ChatRoomMessageRow) {
  const list = messages.get(roomId) ?? [];
  list.push(row);
  if (list.length > 200) list.splice(0, list.length - 200);
  messages.set(roomId, list);
  return row;
}

export function isSiteAdmin(user: Pick<User, "username" | "role"> | null) {
  if (!user) return false;
  const role = (user.role ?? "").toLowerCase();
  if (role === "admin" || role === "superadmin" || role === "moderator") return true;
  const uname = (user.username ?? "").trim().toLowerCase();
  return uname === "admin" || uname === "destek" || uname === "moderator";
}

export function roomPrivileges(
  user: Pick<User, "id" | "username" | "role"> | null,
  room: ChatRoomRow,
) {
  const admin = isSiteAdmin(user);
  const owner =
    admin ||
    (user != null &&
      (room.ownerId === user.id ||
        room.slug.toLowerCase() === (user.username ?? "").toLowerCase()));
  const dj =
    owner ||
    (user != null && room.djUserIds.includes(user.id));
  return { admin, owner, dj, canModerate: admin || owner };
}

export function toChatUser(user: User, chatRole?: string): ChatRoomUser {
  const admin = isSiteAdmin(user);
  return {
    id: user.id,
    name: user.displayName ?? user.username ?? "Kullanıcı",
    nickname: user.username,
    image: user.avatarUrl,
    chatRole: admin ? "admin" : chatRole ?? "listener",
    roleSymbol: admin ? "👑" : null,
    membership: user.membership,
  };
}

export async function joinPresence(roomId: string, user: User) {
  const room = getChatRoom(roomId);
  if (!room) return null;
  const priv = roomPrivileges(user, room);
  const chatRole = priv.admin
    ? "admin"
    : priv.owner
      ? "owner"
      : priv.dj
        ? "dj"
        : "listener";
  const row: ChatPresenceRow = {
    ...toChatUser(user, chatRole),
    seatIndex: priv.owner || priv.admin ? 1 : null,
    isSpeaking: priv.owner || priv.admin,
    joinedAt: Date.now(),
  };
  const wasIn = roomMap(roomId).has(user.id);
  roomMap(roomId).set(user.id, row);

  let systemMsg: ChatRoomMessageRow | null = null;
  if (!wasIn) {
    const vip = priv.admin || priv.owner || chatRole === "dj";
    const tag = vip ? "VIP" : "USER";
    systemMsg = pushMessage(roomId, {
      id: randomUUID(),
      content: `[SYSTEM_VIP_JOIN:${tag}:${row.name}]`,
      createdAt: new Date().toISOString(),
      user: row,
    });
  }
  return { presence: [...roomMap(roomId).values()], systemMsg };
}

export function leavePresence(roomId: string, userId: string) {
  const m = roomMap(roomId);
  const prev = m.get(userId);
  m.delete(userId);
  let systemMsg: ChatRoomMessageRow | null = null;
  if (prev) {
    systemMsg = pushMessage(roomId, {
      id: randomUUID(),
      content: `[SYSTEM_LEAVE]${prev.name}`,
      createdAt: new Date().toISOString(),
    });
  }
  return { presence: [...m.values()], systemMsg };
}

export function listPresence(roomId: string) {
  return [...roomMap(roomId).values()];
}

export async function addTextMessage(roomId: string, user: User, content: string) {
  const trimmed = content.trim();
  if (!trimmed) return null;
  const room = getChatRoom(roomId);
  if (!room) return null;
  const priv = roomPrivileges(user, room);
  const row = pushMessage(roomId, {
    id: randomUUID(),
    content: trimmed,
    createdAt: new Date().toISOString(),
    user: toChatUser(
      user,
      priv.admin ? "admin" : priv.owner ? "owner" : "listener",
    ),
  });
  return row;
}

export function requestSpeak(roomId: string, userId: string) {
  let set = speakRequests.get(roomId);
  if (!set) {
    set = new Set();
    speakRequests.set(roomId, set);
  }
  set.add(userId);
  return [...set];
}

export function cancelSpeakRequest(roomId: string, userId: string) {
  speakRequests.get(roomId)?.delete(userId);
  return [...(speakRequests.get(roomId) ?? [])];
}

export function listSpeakRequests(roomId: string) {
  return [...(speakRequests.get(roomId) ?? [])];
}

export function approveSpeak(roomId: string, userId: string) {
  speakRequests.get(roomId)?.delete(userId);
  const p = roomMap(roomId).get(userId);
  if (p) {
    p.seatIndex = 2;
    p.isSpeaking = true;
    roomMap(roomId).set(userId, p);
  }
  return p;
}

export function getDjState(roomId: string, user: User | null) {
  const room = getChatRoom(roomId);
  const dj = djByRoom.get(roomId) ?? {
    activeDjId: room?.activeDjId ?? null,
    musicUrl: null,
    playing: false,
  };
  const priv = room && user ? roomPrivileges(user, room) : null;
  const djUsers = listPresence(roomId).filter(
    (p) =>
      p.chatRole === "dj" ||
      p.chatRole === "owner" ||
      p.chatRole === "admin" ||
      (room?.djUserIds.includes(p.id) ?? false),
  );
  return {
    djUsers,
    activeDjId: dj.activeDjId,
    musicUrl: dj.musicUrl,
    playing: dj.playing,
    ownerPresent: room?.ownerId
      ? roomMap(roomId).has(room.ownerId)
      : false,
    canPlayMusic: Boolean(priv?.owner || priv?.admin || priv?.dj),
    isOwner: Boolean(priv?.owner),
  };
}

export function setDjMusic(roomId: string, user: User, musicUrl: string | null, playing: boolean) {
  const room = getChatRoom(roomId);
  if (!room) return null;
  const priv = roomPrivileges(user, room);
  if (!priv.owner && !priv.admin && !priv.dj) return null;
  const next = {
    activeDjId: user.id,
    musicUrl,
    playing: playing && Boolean(musicUrl),
  };
  djByRoom.set(roomId, next);
  return next;
}

export function setRoomBackground(roomId: string, user: User, url: string) {
  const room = rooms.find((r) => r.id === roomId);
  if (!room) return null;
  const priv = roomPrivileges(user, room);
  if (!priv.owner && !priv.admin) return null;
  if (!SITE_BACKGROUNDS.includes(url)) return null;
  room.backgroundImage = url;
  return room;
}

export async function loadUser(userId: string | undefined) {
  if (!userId) return null;
  return prisma.user.findUnique({ where: { id: userId } });
}
