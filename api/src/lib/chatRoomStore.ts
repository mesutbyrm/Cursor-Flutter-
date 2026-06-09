import { randomUUID } from "node:crypto";
import type { User } from "@prisma/client";
import { prisma } from "./prisma";
import {
  searchMusicViaYoutubeApi,
  toLegacyYoutubeHits,
} from "./youtubeMusicSearch";
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

const SITE_BACKGROUNDS = Array.from({ length: 20 }, (_, i) =>
  `https://canlifal.com/images/voice-bg-${i + 1}.jpg`,
);

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
const roomBannedWords = new Map<string, Set<string>>();
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

export async function joinPresence(
  roomId: string,
  user: User,
  opts?: { nickname?: string | null },
) {
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
  const customNick = opts?.nickname?.trim().slice(0, 32);
  const base = toChatUser(user, chatRole);
  const row: ChatPresenceRow = {
    ...base,
    nickname: customNick || base.nickname,
    name: customNick || base.name,
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

export function clearRoomMessages(roomId: string) {
  messageList(roomId).splice(0, messageList(roomId).length);
}

function tryHandleRoomCommand(
  room: ChatRoomRow,
  actor: User,
  roomId: string,
  raw: string,
): ChatRoomMessageRow | null {
  let cmd = raw.trim();
  if (cmd.startsWith("!")) cmd = `/${cmd.slice(1)}`;
  else if (!cmd.startsWith("/")) return null;
  const priv = roomPrivileges(actor, room);
  const parts = cmd.split(/\s+/).filter(Boolean);
  const head = (parts[0] ?? "").toLowerCase();

  const system = (content: string) =>
    pushMessage(roomId, {
      id: randomUUID(),
      content,
      createdAt: new Date().toISOString(),
      user: toChatUser(actor, priv.admin ? "admin" : "listener"),
    });

  if (head === "/temizle") {
    if (!priv.canModerate && !priv.owner) {
      return system("⚠️ Sohbeti temizlemek için yetkiniz yok.");
    }
    clearRoomMessages(roomId);
    return system("🧹 Sohbet akışı temizlendi.");
  }

  if (head === "/duyuru") {
    const text = parts.slice(1).join(" ").trim();
    if (!priv.canModerate && !priv.owner) {
      return system("⚠️ Duyuru yayınlamak için yetkiniz yok.");
    }
    if (!text) return system("⚠️ Kullanım: /duyuru mesajınız");
    return system(`📢 DUYURU: ${text}`);
  }

  if (head === "/muzik" || head === "/music") {
    return system("🎵 Müzik kuyruğu «Müzik Aç» veya DJ ayarlarından yönetilir.");
  }

  if (head === "/istek") {
    const song = parts.slice(1).join(" ").trim();
    if (!song) {
      return system(
        "🎵 Şarkı isteği: sağdaki ♫ veya «Müzik Aç» ile ara. Her istek 10 jeton.",
      );
    }
    return system(
      `🎵 Şarkı isteği alındı: «${song}» — işleniyor…`,
    );
  }

  if (head === "/kural" || head === "/kurallar") {
    const rules =
      room.rules?.trim() ||
      room.descTr?.trim() ||
      "Saygılı olun, spam yapmayın, reklam yasaktır.";
    return system(`📜 Oda kuralları:\n${rules}`);
  }

  if (head === "/bilgi") {
    return system(
      `ℹ️ Oda: ${room.nameTr} · ID: ${room.slug}\nÇevrimiçi: ${room.onlineCount}`,
    );
  }

  if (head === "/yardim" || head === "/help") {
    return system(
      "📖 Komutlar: !istek, !kural, !bilgi, !yardım · Yetkililer: !ban, !sessiz, !at, !temizle, !duyuru, !yetki",
    );
  }

  if (head === "/ban") {
    if (!priv.canModerate && !priv.owner) {
      return system("⚠️ Ban için yetkiniz yok.");
    }
    const target = parts[1]?.replace(/^@/, "") ?? "";
    if (!target) return system("⚠️ Kullanım: !ban kullanıcı");
    return system(`⛔ Ban isteği: ${target} (mobil: kullanıcı menüsünden onaylayın)`);
  }

  if (head === "/at" || head === "/kick") {
    if (!priv.canModerate && !priv.owner) {
      return system("⚠️ Atma için yetkiniz yok.");
    }
    const target = parts[1]?.replace(/^@/, "") ?? "";
    if (!target) return system("⚠️ Kullanım: !at kullanıcı");
    return system(`👢 ${target} odadan atıldı (simülasyon — REST ban önerilir)`);
  }

  if (head === "/sessiz" || head === "/mute") {
    if (!priv.canModerate && !priv.owner) {
      return system("⚠️ Susturma için yetkiniz yok.");
    }
    const target = parts[1]?.replace(/^@/, "") ?? "";
    if (!target) return system("⚠️ Kullanım: !sessiz kullanıcı");
    return system(`🔇 ${target} 30 dakika susturuldu (kayıt)`);
  }

  if (head === "/yetki") {
    if (!priv.canModerate && !priv.owner) {
      return system("⚠️ Rol vermek için yetkiniz yok.");
    }
    const target = parts[1]?.replace(/^@/, "") ?? "";
    const sym = parts[2] ?? "";
    if (!target || !sym) {
      return system("⚠️ Kullanım: !yetki kullanıcı sembol (~ % & @ +)");
    }
    return system(`✅ ${target} rol sembolü: ${sym}`);
  }

  return null;
}

export const VOICE_ROOM_NORMAL_COST = 100;
export const VOICE_ROOM_VIP_COST = 5000;

export async function createVoiceChatRoom(
  user: User,
  input: { vip?: boolean; cost?: number; name?: string },
) {
  const vip = input.vip === true;
  const cost = input.cost ?? (vip ? VOICE_ROOM_VIP_COST : VOICE_ROOM_NORMAL_COST);
  const dbUser = await loadUser(user.id);
  if (!dbUser) return { ok: false as const, error: "Oturum gerekli" };
  if (dbUser.coins < cost) {
    return {
      ok: false as const,
      error: `Yetersiz jeton (${cost} gerekli, ${dbUser.coins} mevcut)`,
    };
  }
  await prisma.user.update({
    where: { id: user.id },
    data: { coins: { decrement: cost } },
  });
  const baseName =
    (input.name?.trim() || dbUser.displayName || dbUser.username || "Sohbet").slice(
      0,
      40,
    );
  const slugBase = baseName
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 24);
  const slug = `${slugBase || "oda"}-${Date.now().toString(36).slice(-6)}`;
  const id = `room-${randomUUID().slice(0, 12)}`;
  const row: ChatRoomRow = {
    id,
    slug,
    nameTr: baseName,
    descTr: vip ? "VIP sesli sohbet odası" : "Sesli sohbet odası",
    icon: vip ? "⭐" : "🎤",
    onlineCount: 0,
    userCount: 0,
    backgroundImage: SITE_BACKGROUNDS[0],
    ownerId: user.id,
    owner: {
      id: user.id,
      displayName: dbUser.displayName ?? dbUser.username,
      image: dbUser.avatarUrl,
    },
    activeDjId: null,
    djUserIds: [],
    recentUsers: [],
    rules: "Saygılı olun, spam yapmayın.",
  };
  rooms.push(row);
  return { ok: true as const, room: row, newBalance: dbUser.coins - cost };
}

function bannedWordsForRoom(roomId: string) {
  const id = resolveRoomId(roomId);
  let set = roomBannedWords.get(id);
  if (!set) {
    set = new Set();
    roomBannedWords.set(id, set);
  }
  return set;
}

export function listRoomBannedWords(roomId: string): string[] {
  return [...bannedWordsForRoom(roomId)].sort();
}

export function addRoomBannedWord(roomId: string, actor: User, word: string) {
  const room = getChatRoom(roomId);
  if (!room) return { ok: false as const, error: "Oda bulunamadı" };
  const priv = roomPrivileges(actor, room);
  if (!priv.canModerate) return { ok: false as const, error: "Yetki yok" };
  const w = word.trim().toLowerCase();
  if (w.length < 2) return { ok: false as const, error: "Kelime çok kısa" };
  bannedWordsForRoom(roomId).add(w);
  return { ok: true as const, words: listRoomBannedWords(roomId) };
}

export function removeRoomBannedWord(roomId: string, actor: User, word: string) {
  const room = getChatRoom(roomId);
  if (!room) return { ok: false as const, error: "Oda bulunamadı" };
  const priv = roomPrivileges(actor, room);
  if (!priv.canModerate) return { ok: false as const, error: "Yetki yok" };
  bannedWordsForRoom(roomId).delete(word.trim().toLowerCase());
  return { ok: true as const, words: listRoomBannedWords(roomId) };
}

function containsBannedWord(roomId: string, text: string) {
  const lower = text.toLowerCase();
  for (const w of bannedWordsForRoom(roomId)) {
    if (w.length >= 2 && lower.includes(w)) return true;
  }
  return false;
}

export async function addTextMessage(roomId: string, user: User, content: string) {
  const trimmed = content.trim();
  if (!trimmed) return null;
  if (isRoomBanned(roomId, user.id)) return null;
  const room = getChatRoom(roomId);
  if (!room) return null;
  const priv = roomPrivileges(user, room);
  let cmd = trimmed;
  if (cmd.startsWith("!")) cmd = `/${cmd.slice(1)}`;
  const head = (cmd.split(/\s+/).filter(Boolean)[0] ?? "").toLowerCase();
  if (head === "/istek") {
    const song = cmd.replace(/^\/istek\s*/i, "").trim();
    if (song.length >= 2) {
      const hits = await searchYoutube(song);
      if (hits.length > 0) {
        const hit = hits[0]!;
        const result = await requestMusicQueue(roomId, user, {
          title: hit.title,
          youtubeUrl: hit.url,
          thumbUrl: hit.thumbUrl ?? null,
          skipPayment: true,
          priority: false,
        });
        if (result.ok) {
          return pushMessage(roomId, {
            id: randomUUID(),
            content: trimmed,
            createdAt: new Date().toISOString(),
            user: toChatUser(
              user,
              priv.admin ? "admin" : priv.owner ? "owner" : "listener",
            ),
          });
        }
        return pushMessage(roomId, {
          id: randomUUID(),
          content: `⚠️ ${result.error ?? "Şarkı isteği başarısız"}`,
          createdAt: new Date().toISOString(),
          user: toChatUser(user, "listener"),
        });
      }
      return pushMessage(roomId, {
        id: randomUUID(),
        content: `⚠️ «${song}» için sonuç bulunamadı.`,
        createdAt: new Date().toISOString(),
        user: toChatUser(user, "listener"),
      });
    }
  }
  const commandRow = tryHandleRoomCommand(room, user, roomId, trimmed);
  if (commandRow) return commandRow;
  if (!priv.canModerate && containsBannedWord(roomId, trimmed)) {
    return pushMessage(roomId, {
      id: randomUUID(),
      content: "⚠️ Mesajınız yasaklı kelime içeriyor.",
      createdAt: new Date().toISOString(),
      user: toChatUser(user, "listener"),
    });
  }
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
  const settings = getRoomMusicSettings(roomId);
  const queue = listMusicQueue(roomId);
  const playing = Boolean(
    dj.playing && (dj.musicUrl || queue.length > 0),
  );
  const isDj =
    Boolean(priv?.dj) ||
    (room?.djUserIds.includes(user?.id ?? "") ?? false);
  const canRequestMusic =
    settings.musicEnabled &&
    Boolean(
      user &&
        (isDj ||
          priv?.owner ||
          priv?.admin ||
          (user.coins ?? 0) >= settings.musicRequestCost),
    );
  return {
    djUsers,
    activeDjId: dj.activeDjId,
    musicUrl: dj.musicUrl,
    playing,
    backgroundImage: room?.backgroundImage ?? null,
    ownerPresent: room?.ownerId
      ? roomMap(roomId).has(room.ownerId)
      : false,
    canPlayMusic: Boolean(priv?.owner || priv?.admin || priv?.dj),
    canRequestMusic,
    isOwner: Boolean(priv?.owner),
    musicQueue: queue,
    nowPlaying: queue.length > 0 ? queue[0]! : null,
    musicRequestCost: settings.musicRequestCost,
    maxMusicQueue: settings.maxQueueLength,
    musicEnabled: settings.musicEnabled,
    maxDj: 5,
  };
}

export async function setDjMusic(
  roomId: string,
  user: User,
  musicUrl: string | null,
  playing: boolean,
) {
  const room = getChatRoom(roomId);
  if (!room) return null;
  const priv = roomPrivileges(user, room);
  if (!priv.owner && !priv.admin && !priv.dj) return null;
  let resolved = musicUrl;
  if (resolved && /youtube\.com|youtu\.be/i.test(resolved)) {
    resolved = (await resolveYoutubeStreamUrl(resolved)) ?? resolved;
  }
  const next = {
    activeDjId: user.id,
    musicUrl: resolved,
    playing: playing && Boolean(resolved),
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
export const DEFAULT_MAX_MUSIC_QUEUE = 20;

export type RoomMusicSettings = {
  musicEnabled: boolean;
  musicRequestCost: number;
  maxQueueLength: number;
};

const musicSettingsByRoom = new Map<string, RoomMusicSettings>();

export function getRoomMusicSettings(roomId: string): RoomMusicSettings {
  const key = resolveRoomId(roomId);
  return (
    musicSettingsByRoom.get(key) ?? {
      musicEnabled: true,
      musicRequestCost: MUSIC_REQUEST_JETON,
      maxQueueLength: DEFAULT_MAX_MUSIC_QUEUE,
    }
  );
}

export function setRoomMusicSettings(
  roomId: string,
  actor: User,
  input: Partial<RoomMusicSettings>,
) {
  const room = getChatRoom(roomId);
  if (!room) return { ok: false as const, error: "Oda bulunamadı" };
  const priv = roomPrivileges(actor, room);
  if (!priv.owner) return { ok: false as const, error: "Yalnızca oda sahibi ayarlayabilir" };
  const key = resolveRoomId(roomId);
  const prev = getRoomMusicSettings(roomId);
  const next: RoomMusicSettings = {
    musicEnabled: input.musicEnabled ?? prev.musicEnabled,
    musicRequestCost: Math.min(
      500,
      Math.max(1, input.musicRequestCost ?? prev.musicRequestCost),
    ),
    maxQueueLength: Math.min(
      50,
      Math.max(1, input.maxQueueLength ?? prev.maxQueueLength),
    ),
  };
  musicSettingsByRoom.set(key, next);
  return { ok: true as const, settings: next };
}

export const POPULAR_MUSIC_SUGGESTIONS = [
  {
    title: "Tutamıyorum Zamanı",
    artist: "Müslüm Gürses",
    query: "Müslüm Gürses Tutamıyorum Zamanı",
    videoId: "c9Fq8_Q5Wx8",
  },
  { title: "Beni Yak", artist: "Duman", query: "Duman Beni Yak", videoId: "v0Kpfr2E3W0" },
  { title: "Yalan", artist: "Tarkan", query: "Tarkan Yalan", videoId: "nboC0smLRsE" },
  { title: "Gülümse", artist: "Sezen Aksu", query: "Sezen Aksu Gülümse", videoId: "0p8yZ7-m3eY" },
  { title: "Aşk", artist: "Tarkan", query: "Tarkan Aşk", videoId: "1VRmoDGxiWQ" },
  { title: "Kum Gibi", artist: "Ahmet Kaya", query: "Ahmet Kaya Kum Gibi", videoId: "4sakaTjeb50" },
  { title: "Islak Islak", artist: "Ferdi Tayfur", query: "Ferdi Tayfur Islak Islak", videoId: "m1Q9Z8v5_2E" },
  { title: "Şımarık", artist: "Tarkan", query: "Tarkan Şımarık", videoId: "7LZG9RXx0pY" },
];

export type MusicQueueItem = {
  id: string;
  title: string;
  youtubeUrl: string;
  thumbUrl?: string | null;
  requestedBy: ChatRoomUser;
  createdAt: string;
  giftTo?: string | null;
  note?: string | null;
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
  input: {
    title: string;
    youtubeUrl: string;
    thumbUrl?: string | null;
    giftTo?: string | null;
    note?: string | null;
    /** Ücretli müzik ikonu isteği — çalan şarkının hemen arkasına */
    priority?: boolean;
    /** Chat !istek — jeton düşülmez */
    skipPayment?: boolean;
  },
) {
  const room = getChatRoom(roomId);
  if (!room) return { ok: false as const, error: "Oda bulunamadı" };
  const url = input.youtubeUrl.trim();
  if (!url) return { ok: false as const, error: "YouTube bağlantısı gerekli" };
  const settings = getRoomMusicSettings(roomId);
  if (!settings.musicEnabled) {
    return { ok: false as const, error: "DJ sistemi bu odada kapalı" };
  }
  const priv = roomPrivileges(user, room);
  const isDj =
    priv.dj || priv.owner || priv.admin || room.djUserIds.includes(user.id);
  const dbUser = await loadUser(user.id);
  if (!dbUser) return { ok: false as const, error: "Oturum gerekli" };
  const cost = settings.musicRequestCost;
  const skipPayment = input.skipPayment === true || isDj;
  if (!skipPayment && dbUser.coins < cost) {
    return {
      ok: false as const,
      error: `Bu şarkıyı istemek için en az ${cost} jeton gerekli.`,
    };
  }
  const listBefore = musicQueueList(roomId);
  if (listBefore.length >= settings.maxQueueLength) {
    return {
      ok: false as const,
      error: `Kuyruk dolu (maks. ${settings.maxQueueLength})`,
    };
  }
  let newBalance = dbUser.coins;
  if (!skipPayment) {
    const updated = await prisma.user.update({
      where: { id: user.id },
      data: { coins: { decrement: cost } },
    });
    newBalance = updated.coins;
  }
  const giftTo = input.giftTo?.trim() || null;
  const note = input.note?.trim() || null;
  const item: MusicQueueItem = {
    id: randomUUID(),
    title: input.title.trim() || "Şarkı",
    youtubeUrl: url,
    thumbUrl: input.thumbUrl ?? null,
    requestedBy: toChatUser(user, "listener"),
    createdAt: new Date().toISOString(),
    giftTo,
    note,
  };
  const list = musicQueueList(roomId);
  const key = resolveRoomId(roomId);
  const djNow = djByRoom.get(key);
  const wasPlaying = Boolean(djNow?.playing && djNow.musicUrl);
  const usePriority = input.priority === true && !isDj;
  let queuePosition: number;
  if (usePriority && wasPlaying && list.length > 0) {
    list.splice(1, 0, item);
    queuePosition = 2;
  } else if (usePriority && !wasPlaying) {
    list.unshift(item);
    queuePosition = 1;
  } else {
    list.push(item);
    queuePosition = list.length;
  }
  if (list.length > settings.maxQueueLength) {
    list.splice(0, list.length - settings.maxQueueLength);
  }
  const canonical = key;
  const displayName = item.requestedBy.name;
  if (usePriority) {
    pushMessage(canonical, {
      id: randomUUID(),
      content: `⚡ Öncelikli istek: «${item.title}» (çalan şarkının ardından)`,
      createdAt: new Date().toISOString(),
      user: item.requestedBy,
    });
  }
  pushMessage(canonical, {
    id: randomUUID(),
    content: `🎵 ${displayName} "${item.title}" şarkısını istedi.`,
    createdAt: new Date().toISOString(),
    user: item.requestedBy,
  });
  if (giftTo) {
    pushMessage(canonical, {
      id: randomUUID(),
      content: `🎁 ${displayName} bu şarkıyı tüm odaya armağan etti.`,
      createdAt: new Date().toISOString(),
      user: item.requestedBy,
    });
  }
  pushMessage(canonical, {
    id: randomUUID(),
    content: `📀 Şarkı kuyruğa eklendi.`,
    createdAt: new Date().toISOString(),
    user: item.requestedBy,
  });
  pushMessage(canonical, {
    id: randomUUID(),
    content: `🔢 Sıra: #${queuePosition}`,
    createdAt: new Date().toISOString(),
    user: item.requestedBy,
  });
  await tryStartMusicFromQueue(roomId);
  const dj = djByRoom.get(key);
  return {
    ok: true as const,
    item,
    queue: [...list],
    queuePosition,
    startedImmediately: !wasPlaying && queuePosition === 1,
    newBalance,
    musicUrl: dj?.musicUrl ?? null,
    playing: dj?.playing ?? false,
  };
}

function canManageMusicQueue(user: User, room: ChatRoomRow) {
  const priv = roomPrivileges(user, room);
  return priv.owner || priv.canModerate || priv.admin || priv.dj;
}

export async function skipMusicQueue(roomId: string, user: User) {
  const room = getChatRoom(roomId);
  if (!room) return { ok: false as const, error: "Oda bulunamadı" };
  if (!canManageMusicQueue(user, room)) {
    return { ok: false as const, error: "Şarkı atlama yetkisi yok" };
  }
  await advanceMusicQueue(roomId);
  pushMessage(resolveRoomId(roomId), {
    id: randomUUID(),
    content: `⏭️ ${user.displayName ?? user.username} şarkıyı atladı.`,
    createdAt: new Date().toISOString(),
  });
  return { ok: true as const, queue: listMusicQueue(roomId) };
}

export function removeMusicQueueItem(
  roomId: string,
  user: User,
  itemId: string,
) {
  const room = getChatRoom(roomId);
  if (!room) return { ok: false as const, error: "Oda bulunamadı" };
  if (!canManageMusicQueue(user, room)) {
    return { ok: false as const, error: "Yetki yok" };
  }
  const list = musicQueueList(roomId);
  const idx = list.findIndex((i) => i.id === itemId);
  if (idx < 0) return { ok: false as const, error: "Şarkı bulunamadı" };
  const removed = list.splice(idx, 1)[0];
  pushMessage(resolveRoomId(roomId), {
    id: randomUUID(),
    content: `🗑️ Kuyruktan kaldırıldı: ${removed.title}`,
    createdAt: new Date().toISOString(),
  });
  return { ok: true as const, queue: [...list] };
}

export function clearMusicQueue(roomId: string, user: User) {
  const room = getChatRoom(roomId);
  if (!room) return { ok: false as const, error: "Oda bulunamadı" };
  if (!canManageMusicQueue(user, room)) {
    return { ok: false as const, error: "Yetki yok" };
  }
  const list = musicQueueList(roomId);
  list.splice(0, list.length);
  const key = resolveRoomId(roomId);
  djByRoom.set(key, { activeDjId: null, musicUrl: null, playing: false });
  pushMessage(key, {
    id: randomUUID(),
    content: `🧹 Müzik kuyruğu temizlendi.`,
    createdAt: new Date().toISOString(),
  });
  return { ok: true as const, queue: [] as MusicQueueItem[] };
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
  duration?: string;
};

export async function searchYoutube(query: string): Promise<YoutubeSearchHit[]> {
  try {
    return toLegacyYoutubeHits(await searchMusicViaYoutubeApi(query));
  } catch {
    return [];
  }
}

const PIPED_API_HOSTS = [
  "https://pipedapi.kavin.rocks",
  "https://pipedapi.adminforge.de",
  "https://pipedapi.syncpundit.io",
  "https://pipedapi.leptons.xyz",
];

async function resolveViaPipedHost(
  host: string,
  videoId: string,
): Promise<string | null> {
  try {
    const res = await fetch(`${host}/streams/${videoId}`, {
      headers: { Accept: "application/json" },
    });
    if (!res.ok) return null;
    const data = (await res.json()) as {
      audioStreams?: Array<{ url?: string; bitrate?: number }>;
      audioOnly?: Array<{ url?: string; bitrate?: number }>;
    };
    const streams = [...(data.audioStreams ?? []), ...(data.audioOnly ?? [])];
    if (streams.length === 0) return null;
    streams.sort((a, b) => (b.bitrate ?? 0) - (a.bitrate ?? 0));
    const url = streams[0]?.url;
    return url && url.startsWith("http") ? url : null;
  } catch {
    return null;
  }
}

export function youtubeWatchUrl(videoId: string) {
  return `https://www.youtube.com/watch?v=${videoId}`;
}

export async function resolveYoutubeStreamUrl(
  youtubeUrlOrId: string,
): Promise<string | null> {
  const id =
    extractYoutubeId(youtubeUrlOrId) ??
    (youtubeUrlOrId.length <= 15 ? youtubeUrlOrId : null);
  if (!id) return null;
  for (const host of PIPED_API_HOSTS) {
    const stream = await resolveViaPipedHost(host, id);
    if (stream) return stream;
  }
  return null;
}

export async function tryStartMusicFromQueue(roomId: string) {
  const key = resolveRoomId(roomId);
  const current = djByRoom.get(key);
  if (current?.playing && current.musicUrl) return current;
  const list = musicQueueList(roomId);
  if (list.length === 0) return current ?? null;
  const next = list[0]!;
  const rawUrl = next.youtubeUrl.trim();
  const videoId =
    extractYoutubeId(rawUrl) ??
    (rawUrl.length <= 15 && !rawUrl.includes("/") ? rawUrl : null);
  const watchUrl = videoId
    ? rawUrl.startsWith("http")
      ? rawUrl
      : youtubeWatchUrl(videoId)
    : rawUrl || null;
  const stream = watchUrl ? await resolveYoutubeStreamUrl(watchUrl) : null;
  const playbackUrl = stream ?? watchUrl;
  if (!playbackUrl) return current ?? null;
  const nextDj = {
    activeDjId: next.requestedBy.id,
    musicUrl: playbackUrl,
    playing: true,
  };
  djByRoom.set(key, nextDj);
  return nextDj;
}

export async function advanceMusicQueue(roomId: string, user?: User) {
  const room = getChatRoom(roomId);
  if (user && room && !canManageMusicQueue(user, room)) {
    return null;
  }
  const key = resolveRoomId(roomId);
  const list = musicQueueList(roomId);
  if (list.length > 0) list.shift();
  djByRoom.set(key, { activeDjId: null, musicUrl: null, playing: false });
  return tryStartMusicFromQueue(roomId);
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
