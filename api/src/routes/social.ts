import { Router } from "express";
import { z } from "zod";
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

const seedRooms = [
  {
    id: "room-1",
    nameTr: "Genel Sohbet",
    descTr: "Herkes hoş geldin",
    onlineCount: 42,
    unreadCount: 3,
    isVoice: true,
    owner: { displayName: "Moderatör", image: "https://canlifal.com/favicon.ico" },
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

socialRouter.get("/chat/rooms", async (_req, res) => {
  return ok(res, { rooms: seedRooms });
});

socialRouter.get("/chat/rooms/:roomId/messages", requireAuth, async (req, res) => {
  const roomId = req.params.roomId;
  return ok(res, {
    items: [
      {
        id: "m-1",
        body: "Merhaba! $roomId odasına hoş geldin.",
        sentAt: new Date().toISOString(),
        sender: { displayName: "Sistem", username: "system" },
      },
    ],
  });
});

socialRouter.get("/announcements", async (_req, res) => {
  return ok(res, { items: seedNotifications });
});

socialRouter.get("/fortune-tellers", async (_req, res) => {
  return ok(res, {
    tellers: [
      {
        id: "ft-1",
        displayName: "Canlı Falcı",
        rating: 4.8,
        pricePerSession: 120,
        isOnline: true,
        specialties: ["tarot"],
        image: "https://canlifal.com/favicon.ico",
      },
    ],
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
