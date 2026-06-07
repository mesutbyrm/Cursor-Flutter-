import { Router } from "express";
import { z } from "zod";
import {
  createFortuneSession,
  fortuneSessionRoleForUser,
  getFortuneSession,
  listIncomingFortuneSessionsForTeller,
  respondFortuneSession,
} from "../lib/liveStreamExtrasStore";
import { prisma } from "../lib/prisma";
import { fail, ok } from "../lib/response";
import { requireAuth } from "../middleware/requireAuth";

function publicProfile(u: {
  id: string;
  email: string;
  displayName: string | null;
  username: string | null;
  bio: string | null;
  avatarUrl: string | null;
  coverUrl: string | null;
  coins: number;
  followerCount: number;
  followingCount: number;
  createdAt: Date;
}) {
  return {
    id: u.id,
    email: u.email,
    displayName: u.displayName ?? u.email.split("@")[0],
    username: u.username ?? u.email.split("@")[0],
    bio: u.bio ?? "",
    avatarUrl: u.avatarUrl ?? "https://canlifal.com/favicon.ico",
    coverUrl: u.coverUrl ?? "https://canlifal.com/apple-touch-icon.png",
    coins: u.coins,
    followers: u.followerCount,
    following: u.followingCount,
    level: 1,
    tier: "free",
    createdAt: u.createdAt.toISOString(),
  };
}

const seedPosts = [
  {
    id: "post-1",
    title: "Canlifal ile canlı yayına hazır mısın?",
    channelName: "Canlifal",
    thumbnailUrl: "https://canlifal.com/apple-touch-icon.png",
    viewCount: 1280,
    duration: "0:45",
  },
  {
    id: "post-2",
    title: "TikTok tarzı dikey feed deneyimi",
    channelName: "Canlifal Social",
    thumbnailUrl: "https://canlifal.com/favicon.ico",
    viewCount: 940,
    duration: "1:12",
  },
];

const seedLive = [
  {
    id: "live-1",
    title: "Gece Sohbeti",
    description: "Canlı yayın odası",
    status: "live",
    viewers: 234,
    thumbnailUrl: "https://canlifal.com/apple-touch-icon.png",
    host: { displayName: "Canlifal Host", username: "host" },
    tags: ["sohbet", "canlı"],
  },
];

const seedNotifications = [
  {
    id: "n-1",
    title: "Yeni takipçi",
    body: "Bir kullanıcı seni takip etti",
    icon: "👤",
    isRead: false,
  },
  {
    id: "n-2",
    title: "Canlı yayın",
    body: "Takip ettiğin yayıncı yayında",
    icon: "🔴",
    isRead: false,
  },
];

export const socialRouter = Router();

socialRouter.get("/trend-videos", async (req, res) => {
  const page = Number(req.query.page ?? 0);
  return ok(res, { videos: seedPosts, page });
});

socialRouter.get("/video-streams", async (_req, res) => {
  return ok(res, { items: seedLive });
});

socialRouter.get("/announcements", async (_req, res) => {
  return ok(res, { items: seedNotifications });
});

/** Falcı profil id → TRTC anchor userId (canlifal.com ile uyumlu). */
function resolveTellerUserId(
  tellerId: string,
  body?: Record<string, unknown>,
): string {
  const fromBody =
    body?.tellerUserId?.toString()?.trim() ||
    body?.userId?.toString()?.trim() ||
    body?.anchorUserId?.toString()?.trim();
  if (fromBody) return fromBody;
  // Seed: ft-* profilleri için sabit demo anchor (gerçek ortamda DB userId gelir).
  if (tellerId.startsWith("ft-")) {
    return `teller-user-${tellerId}`;
  }
  return tellerId;
}

socialRouter.get("/fortune-tellers", async (_req, res) => {
  const tellerId = "ft-1";
  const tellerUserId = resolveTellerUserId(tellerId);
  return ok(res, {
    tellers: [
      {
        id: tellerId,
        userId: tellerUserId,
        tellerUserId,
        displayName: "Canlı Falcı",
        rating: 4.8,
        pricePerMinute: 12,
        pricePerSession: 120,
        isOnline: true,
        specialties: ["tarot"],
        image: "https://canlifal.com/favicon.ico",
      },
    ],
  });
});

/** POST /api/fortune-tellers/session — canlı falcı oturumu */
socialRouter.post("/fortune-tellers/session", requireAuth, async (req, res) => {
  const tellerId =
    req.body?.tellerId?.toString()?.trim() ||
    req.body?.fortuneTellerId?.toString()?.trim();
  if (!tellerId) {
    return fail(res, 400, "BAD_REQUEST", "tellerId gerekli");
  }
  const clientId = req.userId!;
  const tellerUserId = resolveTellerUserId(
    tellerId,
    req.body as Record<string, unknown>,
  );
  const body = req.body as Record<string, unknown>;
  const session = createFortuneSession(tellerId, clientId, tellerUserId, {
    clientName: body?.clientName?.toString(),
    durationMinutes: Number(body?.durationMinutes) || undefined,
    totalJeton: Number(body?.totalJeton) || undefined,
  });
  const role = fortuneSessionRoleForUser(session, clientId);
  return ok(res, {
    session,
    sessionId: session.id,
    tellerId: session.tellerId,
    tellerUserId: session.tellerUserId,
    clientId: session.clientId,
    clientName: session.clientName,
    durationMinutes: session.durationMinutes,
    totalJeton: session.totalJeton,
    trtcRoomId: session.trtcRoomId,
    role,
    isClient: role === "client",
    status: session.status,
    tellerResponse: session.tellerResponse,
  });
});

/** GET /api/fortune-tellers/sessions/incoming — falcıya düşen bekleyen istekler */
socialRouter.get(
  "/fortune-tellers/sessions/incoming",
  requireAuth,
  async (req, res) => {
    const sessions = listIncomingFortuneSessionsForTeller(req.userId!);
    return ok(res, { sessions });
  },
);

/** GET /api/fortune-tellers/session/:sessionId — oturum durumu (danışan poll) */
socialRouter.get(
  "/fortune-tellers/session/:sessionId",
  requireAuth,
  async (req, res) => {
    const session = getFortuneSession(req.params.sessionId);
    if (!session) {
      return fail(res, 404, "NOT_FOUND", "Oturum bulunamadı");
    }
    const uid = req.userId!;
    if (session.clientId !== uid && session.tellerUserId !== uid) {
      return fail(res, 403, "FORBIDDEN", "Yetki yok");
    }
    const role = fortuneSessionRoleForUser(session, uid);
    return ok(res, {
      session,
      sessionId: session.id,
      status: session.status,
      tellerResponse: session.tellerResponse,
      role,
      isClient: role === "client",
    });
  },
);

/** POST /api/fortune-tellers/session/:sessionId/respond — falcı kabul / beklet / red */
socialRouter.post(
  "/fortune-tellers/session/:sessionId/respond",
  requireAuth,
  async (req, res) => {
    const action = req.body?.action?.toString()?.trim().toLowerCase();
    if (!["accept", "hold", "reject"].includes(action ?? "")) {
      return fail(res, 400, "BAD_REQUEST", "action: accept | hold | reject");
    }
    const result = respondFortuneSession(
      req.params.sessionId,
      req.userId!,
      action as "accept" | "hold" | "reject",
    );
    if (!result.ok) {
      return fail(res, 400, "BAD_REQUEST", result.error);
    }
    const session = result.session;
    const role = fortuneSessionRoleForUser(session, req.userId!);
    return ok(res, {
      session,
      sessionId: session.id,
      status: session.status,
      tellerResponse: session.tellerResponse,
      role,
      isClient: role === "client",
    });
  },
);

socialRouter.get("/fortune-tellers/:id", async (req, res) => {
  const id = req.params.id;
  const tellerUserId = resolveTellerUserId(id);
  return ok(res, {
    teller: {
      id,
      userId: tellerUserId,
      tellerUserId,
      displayName: "Canlı Falcı",
      rating: 4.8,
      pricePerMinute: 12,
      pricePerSession: 120,
      isOnline: true,
      specialties: ["tarot"],
      image: "https://canlifal.com/favicon.ico",
    },
  });
});

socialRouter.get("/celebrities/posts/latest", async (_req, res) => {
  return ok(res, {
    posts: seedPosts.map((p) => ({
      id: p.id,
      content: p.title,
      imageUrl: p.thumbnailUrl,
      likeCount: p.viewCount,
      celebrity: { displayName: p.channelName, image: p.thumbnailUrl },
      platform: "canlifal",
      postType: "image",
    })),
  });
});

socialRouter.get("/public-stats", async (_req, res) => {
  const users = await prisma.user.count();
  const recent = await prisma.user.findMany({
    orderBy: { updatedAt: "desc" },
    take: 5,
    select: {
      id: true,
      username: true,
      displayName: true,
      avatarUrl: true,
      updatedAt: true,
    },
  });
  return ok(res, {
    onlineUsers: 1200 + users,
    inGames: Math.round(users * 0.17),
    inSocial: Math.round(users * 0.38),
    onLive: seedLive.length * 42,
    inVoiceChat: 42,
    fortuneActive: Math.round(users * 0.12),
    browsing: Math.round(users * 0.43),
    todayLogins: users * 2,
    users: { total: users, online: 1200 + users },
    video: { activeStreams: seedLive.length },
    chat: { totalOnline: 42 },
    fortunes: { total: 12 },
    recentLogins: recent.map((u, i) => ({
      user: {
        id: u.id,
        username: u.username,
        displayName: u.displayName,
        avatarUrl: u.avatarUrl,
      },
      timeLabel:
        i === 0 ? "Az önce" : `${i + 1} dakika önce`,
      activity: ["El Falı", "Tarot", "Yıldız Falı", "Kahve Falı", "Çevrimiçi"][i % 5],
      activityEmoji: ["✋", "🃏", "⭐", "☕", "✨"][i % 5],
    })),
  });
});

socialRouter.get("/coins/balance", requireAuth, async (req, res) => {
  const user = await prisma.user.findUnique({ where: { id: req.userId! } });
  if (!user) {
    return fail(res, 404, "NOT_FOUND", "Kullanıcı bulunamadı");
  }
  return ok(res, { balance: user.coins, coins: user.coins });
});

const spendSchema = z.object({
  amount: z.number().int().positive(),
  reason: z.string().optional(),
});

socialRouter.post("/coins/spend", requireAuth, async (req, res) => {
  const parsed = spendSchema.safeParse(req.body);
  if (!parsed.success) {
    return fail(res, 400, "VALIDATION_ERROR", "Geçersiz istek", parsed.error.flatten());
  }
  const user = await prisma.user.findUnique({ where: { id: req.userId! } });
  if (!user) {
    return fail(res, 404, "NOT_FOUND", "Kullanıcı bulunamadı");
  }
  if (user.coins < parsed.data.amount) {
    return fail(res, 400, "INSUFFICIENT_COINS", "Yetersiz coin");
  }
  const updated = await prisma.user.update({
    where: { id: user.id },
    data: { coins: { decrement: parsed.data.amount } },
  });
  return ok(res, { balance: updated.coins });
});

socialRouter.get("/users/:userId", async (req, res) => {
  const user = await prisma.user.findUnique({ where: { id: req.params.userId } });
  if (!user) {
    return fail(res, 404, "NOT_FOUND", "Kullanıcı bulunamadı");
  }
  return ok(res, publicProfile(user));
});

socialRouter.post("/users/:userId/follow", requireAuth, async (req, res) => {
  const followerId = req.userId!;
  const followingId = req.params.userId;
  if (followerId === followingId) {
    return fail(res, 400, "INVALID", "Kendinizi takip edemezsiniz");
  }
  const target = await prisma.user.findUnique({ where: { id: followingId } });
  if (!target) {
    return fail(res, 404, "NOT_FOUND", "Kullanıcı bulunamadı");
  }
  await prisma.follow.upsert({
    where: { followerId_followingId: { followerId, followingId } },
    create: { followerId, followingId },
    update: {},
  });
  await prisma.user.update({
    where: { id: followingId },
    data: { followerCount: { increment: 1 } },
  });
  await prisma.user.update({
    where: { id: followerId },
    data: { followingCount: { increment: 1 } },
  });
  const me = await prisma.user.findUnique({ where: { id: followerId } });
  return ok(res, { user: me ? publicProfile(me) : null, isFollowing: true });
});

socialRouter.delete("/users/:userId/follow", requireAuth, async (req, res) => {
  const followerId = req.userId!;
  const followingId = req.params.userId;
  await prisma.follow.deleteMany({ where: { followerId, followingId } });
  await prisma.user.update({
    where: { id: followingId },
    data: { followerCount: { decrement: 1 } },
  });
  await prisma.user.update({
    where: { id: followerId },
    data: { followingCount: { decrement: 1 } },
  });
  const me = await prisma.user.findUnique({ where: { id: followerId } });
  return ok(res, { user: me ? publicProfile(me) : null, isFollowing: false });
});
