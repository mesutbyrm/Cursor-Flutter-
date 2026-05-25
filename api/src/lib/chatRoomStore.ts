import { randomUUID } from "node:crypto";
import type { User } from "@prisma/client";
import { prisma } from "./prisma";
import {
  canModerateRank,
  fullControlRank,
  parseStaffRank,
  rankPower,
  rankSymbol,
  type VoiceStaffRank,
} from "./voiceStaffRank";

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
  "https://canlifal.com/images/voice-bg-3.jpg",
  "https://canlifal.com/images/voice-bg-4.jpg",
  "https://canlifal.com/images/voice-bg-5.jpg",
  "https://canlifal.com/images/voice-bg-6.jpg",
  "https://canlifal.com/images/chat-bg-1.jpg",
  "https://canlifal.com/images/chat-bg-2.jpg",
  "https://canlifal.com/uploads/voice-bg/default.jpg",
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
const roomBans = new Map<string, Set<string>>();
const djByRoom = new Map<
  string,
  { activeDjId: string | null; musicUrl: string | null; playing: boolean }
>();

function roomMap(roomIdOrSlug: string) {
  const roomId = resolveRoomId(roomIdOrSlug);
  let m = presence.get(roomId);
  if (!m) {
    m = new Map();
    presence.set(roomId, m);
  }
  return m;
}

function messageList(roomIdOrSlug: string) {
  const roomId = resolveRoomId(roomIdOrSlug);
  let list = messages.get(roomId);
  if (!list) {
    list = [];
    messages.set(roomId, list);
  }
  return list;
}

function speakSet(roomIdOrSlug: string) {
  const roomId = resolveRoomId(roomIdOrSlug);
  let set = speakRequests.get(roomId);
  if (!set) {
    set = new Set();
    speakRequests.set(roomId, set);
  }
  return set;
}

function banSet(roomIdOrSlug: string) {
  const roomId = resolveRoomId(roomIdOrSlug);
  let set = roomBans.get(roomId);
  if (!set) {
    set = new Set();
    roomBans.set(roomId, set);
  }
  return set;
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

/** slug ve id karışıklığını önler — tüm haritalar canonical id ile çalışır */
export function resolveRoomId(roomIdOrSlug: string): string {
  const room = getChatRoom(roomIdOrSlug);
  return room?.id ?? roomIdOrSlug;
}

export function listMessages(roomId: string, since?: string) {
  const all = messageList(roomId);
  if (!since) return all.slice(-120);
  const t = Date.parse(since);
  if (Number.isNaN(t)) return all.slice(-120);
  return all.filter((m) => Date.parse(m.createdAt) > t);
}

function pushMessage(roomId: string, row: ChatRoomMessageRow) {
  const list = messageList(roomId);
  list.push(row);
  if (list.length > 200) list.splice(0, list.length - 200);
  return row;
}

export function staffRankForUser(
  user: Pick<User, "username" | "role"> | null,
): VoiceStaffRank {
  if (!user) return "none";
  return parseStaffRank(user.username, user.role);
}

export function isSiteAdmin(user: Pick<User, "username" | "role"> | null) {
  return fullControlRank(staffRankForUser(user));
}

export function roomPrivileges(
  user: Pick<User, "id" | "username" | "role"> | null,
  room: ChatRoomRow,
) {
  const rank = staffRankForUser(user);
  const staffPower = rankPower(rank);
  const admin = staffPower >= rankPower("admin");
  const founderControl = staffPower >= rankPower("founder");
  const canModerateStaff = canModerateRank(rank);
  const owner =
    admin ||
    founderControl ||
    (user != null &&
      (room.ownerId === user.id ||
        room.slug.toLowerCase() === (user.username ?? "").toLowerCase()));
  const dj =
    owner ||
    canModerateStaff ||
    (user != null && room.djUserIds.includes(user.id));
  return {
    admin,
    owner,
    dj,
    canModerate: admin || owner || canModerateStaff,
    rank,
    staffPower,
  };
}

export function toChatUser(user: User, chatRole?: string): ChatRoomUser {
  const rank = staffRankForUser(user);
  const sym = rankSymbol(rank);
  const role =
    rank === "founder"
      ? "founder"
      : rank === "sop"
        ? "sop"
        : rank === "op"
          ? "op"
          : rank === "admin"
            ? "admin"
            : chatRole ?? "listener";
  return {
    id: user.id,
    name: user.displayName ?? user.username ?? "Kullanıcı",
    nickname: user.username,
    image: user.avatarUrl,
    chatRole: role,
    roleSymbol: sym ?? (role === "admin" ? "👑" : null),
    membership: user.membership,
  };
}

export function isRoomBanned(roomId: string, userId: string) {
  return banSet(roomId).has(userId);
}

export function listRoomBans(roomId: string) {
  return [...banSet(roomId)];
}

export function banRoomUser(
  roomId: string,
  actor: User,
  targetUserId: string,
  reason?: string,
) {
  const room = getChatRoom(roomId);
  if (!room) return { ok: false as const, error: "Oda bulunamadı" };
  const priv = roomPrivileges(actor, room);
  if (!priv.canModerate) return { ok: false as const, error: "Yetki yok" };
  banSet(roomId).add(targetUserId);
  roomMap(roomId).delete(targetUserId);
  const row = pushMessage(roomId, {
    id: randomUUID(),
    content: `[SYSTEM_BAN]${targetUserId}:${reason ?? "Yasaklandı"}`,
    createdAt: new Date().toISOString(),
    user: toChatUser(actor, "admin"),
  });
  return { ok: true as const, message: row };
}

export function unbanRoomUser(roomId: string, actor: User, targetUserId: string) {
  const room = getChatRoom(roomId);
  if (!room) return { ok: false as const, error: "Oda bulunamadı" };
  const priv = roomPrivileges(actor, room);
  if (!priv.canModerate) return { ok: false as const, error: "Yetki yok" };
  banSet(roomId).delete(targetUserId);
  return { ok: true as const };
}

export async function joinPresence(roomId: string, user: User) {
  const room = getChatRoom(roomId);
  if (!room) return null;
  if (isRoomBanned(roomId, user.id)) {
    return { banned: true as const, presence: [] as ChatPresenceRow[] };
  }
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
    const staff = rankPower(priv.rank) >= rankPower("admin");
    const vip = staff || priv.admin || priv.owner || chatRole === "dj";
    const tag = staff ? "STAFF" : vip ? "VIP" : "USER";
    const sym = rankSymbol(priv.rank) ?? "";
    systemMsg = pushMessage(roomId, {
      id: randomUUID(),
      content: `[SYSTEM_VIP_JOIN:${tag}:${sym}${row.name}]`,
      createdAt: new Date().toISOString(),
      user: row,
    });
  }
  return { presence: [...roomMap(roomId).values()], systemMsg, banned: false as const };
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
  if (isRoomBanned(roomId, user.id)) return null;
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
  const set = speakSet(roomId);
  set.add(userId);
  return [...set];
}

export function cancelSpeakRequest(roomId: string, userId: string) {
  speakSet(roomId).delete(userId);
  return [...speakSet(roomId)];
}

export function listSpeakRequests(roomId: string) {
  return [...speakSet(roomId)];
}

export function approveSpeak(roomId: string, userId: string) {
  speakSet(roomId).delete(userId);
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
  const key = resolveRoomId(roomId);
  const dj = djByRoom.get(key) ?? {
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
    musicQueue: listMusicQueue(roomId),
    musicRequestCost: MUSIC_REQUEST_JETON,
    maxDj: 5,
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
  const key = resolveRoomId(roomId);
  djByRoom.set(key, next);
  return next;
}

export function setRoomBackground(roomId: string, user: User, url: string) {
  const room = getChatRoom(roomId);
  if (!room) return null;
  const priv = roomPrivileges(user, room);
  if (!priv.owner && !priv.canModerate) return null;
  const allowed =
    SITE_BACKGROUNDS.includes(url) ||
    url.startsWith("https://canlifal.com/") ||
    url.startsWith("https://www.canlifal.com/");
  if (!allowed) return null;
  room.backgroundImage = url;
  return room;
}

export async function loadUser(userId: string | undefined) {
  if (!userId) return null;
  return prisma.user.findUnique({ where: { id: userId } });
}

export const MUSIC_REQUEST_JETON = 10;

export type MusicQueueItem = {
  id: string;
  title: string;
  youtubeUrl: string;
  thumbUrl?: string | null;
  requestedBy: ChatRoomUser;
  createdAt: string;
};

const musicQueues = new Map<string, MusicQueueItem[]>();

function musicQueueList(roomIdOrSlug: string) {
  const key = resolveRoomId(roomIdOrSlug);
  let list = musicQueues.get(key);
  if (!list) {
    list = [];
    musicQueues.set(key, list);
  }
  return list;
}

export function listMusicQueue(roomId: string) {
  return [...musicQueueList(roomId)];
}

export async function requestMusicQueue(
  roomId: string,
  user: User,
  input: { title: string; youtubeUrl: string; thumbUrl?: string | null },
) {
  const room = getChatRoom(roomId);
  if (!room) return { ok: false as const, error: "Oda bulunamadı" };
  const url = input.youtubeUrl.trim();
  if (!url) return { ok: false as const, error: "YouTube bağlantısı gerekli" };
  const dbUser = await loadUser(user.id);
  if (!dbUser) return { ok: false as const, error: "Oturum gerekli" };
  if (dbUser.coins < MUSIC_REQUEST_JETON) {
    return { ok: false as const, error: `Yetersiz jeton (${MUSIC_REQUEST_JETON} gerekli)` };
  }
  const updated = await prisma.user.update({
    where: { id: user.id },
    data: { coins: { decrement: MUSIC_REQUEST_JETON } },
  });
  const item: MusicQueueItem = {
    id: randomUUID(),
    title: input.title.trim() || "Şarkı",
    youtubeUrl: url,
    thumbUrl: input.thumbUrl ?? null,
    requestedBy: toChatUser(user, "listener"),
    createdAt: new Date().toISOString(),
  };
  const list = musicQueueList(roomId);
  list.push(item);
  if (list.length > 50) list.splice(0, list.length - 50);
  const canonical = resolveRoomId(roomId);
  pushMessage(canonical, {
    id: randomUUID(),
    content: `🎵 ${item.requestedBy.name} sıraya ekledi: ${item.title} (−${MUSIC_REQUEST_JETON} jeton)`,
    createdAt: new Date().toISOString(),
    user: item.requestedBy,
  });
  return {
    ok: true as const,
    item,
    queue: [...list],
    newBalance: updated.coins,
  };
}

export function addRoomDj(roomId: string, actor: User, targetUserId: string) {
  const room = getChatRoom(roomId);
  if (!room) return { ok: false as const, error: "Oda bulunamadı" };
  const priv = roomPrivileges(actor, room);
  if (!priv.owner && !priv.admin) return { ok: false as const, error: "Yetki yok" };
  if (room.djUserIds.length >= 5 && !room.djUserIds.includes(targetUserId)) {
    return { ok: false as const, error: "En fazla 5 DJ" };
  }
  if (!room.djUserIds.includes(targetUserId)) {
    room.djUserIds.push(targetUserId);
  }
  const p = roomMap(roomId).get(targetUserId);
  if (p) {
    p.chatRole = "dj";
    roomMap(roomId).set(targetUserId, p);
  }
  return { ok: true as const, djUserIds: [...room.djUserIds] };
}

export function removeRoomDj(roomId: string, actor: User, targetUserId: string) {
  const room = getChatRoom(roomId);
  if (!room) return { ok: false as const, error: "Oda bulunamadı" };
  const priv = roomPrivileges(actor, room);
  if (!priv.owner && !priv.admin) return { ok: false as const, error: "Yetki yok" };
  room.djUserIds = room.djUserIds.filter((id) => id !== targetUserId);
  const p = roomMap(roomId).get(targetUserId);
  if (p && p.chatRole === "dj") {
    p.chatRole = "listener";
    roomMap(roomId).set(targetUserId, p);
  }
  return { ok: true as const, djUserIds: [...room.djUserIds] };
}

export type YoutubeSearchHit = {
  videoId: string;
  title: string;
  url: string;
  thumbUrl?: string;
  uploader?: string;
};

export async function searchYoutube(query: string): Promise<YoutubeSearchHit[]> {
  const q = query.trim();
  if (q.length < 2) return [];
  if (/youtube\.com|youtu\.be/i.test(q)) {
    const id = extractYoutubeId(q);
    if (!id) return [];
    return [
      {
        videoId: id,
        title: "YouTube bağlantısı",
        url: `https://www.youtube.com/watch?v=${id}`,
        thumbUrl: `https://i.ytimg.com/vi/${id}/hqdefault.jpg`,
      },
    ];
  }
  try {
    const res = await fetch(
      `https://pipedapi.kavin.rocks/search?q=${encodeURIComponent(q)}&filter=music_songs`,
      { headers: { Accept: "application/json" } },
    );
    if (!res.ok) return [];
    const data = (await res.json()) as { items?: Array<Record<string, unknown>> };
    const items = data.items ?? [];
    return items.slice(0, 12).flatMap((row) => {
      const rawUrl = String(row.url ?? "");
      let id = "";
      const vMatch = rawUrl.match(/[?&]v=([a-zA-Z0-9_-]{6,})/);
      if (vMatch) id = vMatch[1];
      else if (rawUrl.startsWith("/")) {
        const parts = rawUrl.split("/").filter(Boolean);
        id = parts[parts.length - 1] ?? "";
      } else {
        id = String(row.id ?? "");
      }
      id = id.replace(/[^a-zA-Z0-9_-]/g, "").slice(0, 11);
      if (id.length < 6) return [];
      return [
        {
          videoId: id,
          title: String(row.title ?? "Video"),
          url: `https://www.youtube.com/watch?v=${id}`,
          thumbUrl: row.thumbnail
            ? String((row.thumbnail as string) ?? "")
            : `https://i.ytimg.com/vi/${id}/hqdefault.jpg`,
          uploader: row.uploaderName ? String(row.uploaderName) : undefined,
        },
      ];
    });
  } catch {
    return [];
  }
}

function extractYoutubeId(raw: string) {
  try {
    const u = new URL(raw.trim());
    if (u.hostname.includes("youtu.be")) {
      return u.pathname.replace("/", "").slice(0, 11);
    }
    return u.searchParams.get("v")?.slice(0, 11) ?? null;
  } catch {
    const m = raw.match(/(?:v=|youtu\.be\/)([a-zA-Z0-9_-]{6,})/);
    return m?.[1] ?? null;
  }
}
