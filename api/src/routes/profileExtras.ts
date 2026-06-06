import { Router } from "express";
import { prisma } from "../lib/prisma";
import { fail, ok } from "../lib/response";
import { requireAuth } from "../middleware/requireAuth";
import { publicUserPayload } from "../lib/auth_user";
import {
  getActivity,
  getBroadcastHistory,
  patchActivityMarkAllRead,
} from "../lib/userProfileApiHandlers";

export const profileExtrasRouter = Router();

/** GET /api/users/search?q= — kullanıcı araması */
profileExtrasRouter.get("/search", requireAuth, async (req, res) => {
  const q = String(req.query.q ?? "").trim();
  if (q.length < 2) {
    return res.status(200).json({ users: [], items: [] });
  }
  const rows = await prisma.user.findMany({
    where: {
      OR: [
        { username: { contains: q, mode: "insensitive" } },
        { displayName: { contains: q, mode: "insensitive" } },
        { email: { contains: q, mode: "insensitive" } },
      ],
    },
    take: 24,
    orderBy: { followerCount: "desc" },
  });
  const users = rows.map((u) => publicUserPayload(u));
  return res.status(200).json({ users, items: users });
});

profileExtrasRouter.get("/lookup/:username", async (req, res) => {
  const username = req.params.username.replace(/^@/, "").trim().toLowerCase();
  const user = await prisma.user.findFirst({
    where: { username: { equals: username, mode: "insensitive" } },
  });
  if (!user) {
    return fail(res, 404, "NOT_FOUND", "Kullanıcı bulunamadı");
  }
  return ok(res, { user: publicUserPayload(user) });
});

profileExtrasRouter.get("/me/stats", requireAuth, async (req, res) => {
  const userId = req.userId!;
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) return fail(res, 404, "NOT_FOUND", "Kullanıcı bulunamadı");

  const posts = await prisma.socialPost.aggregate({
    where: { authorId: userId },
    _sum: { likesCount: true, viewCount: true },
    _count: { id: true },
  });

  const streams = await prisma.giftEvent.findMany({
    where: {
      OR: [{ receiverId: userId }, { senderId: userId }],
      streamId: { not: null },
    },
    select: { streamId: true },
    distinct: ["streamId"],
  });

  const giftsReceived = await prisma.giftEvent.aggregate({
    where: { receiverId: userId },
    _sum: { coinCost: true, quantity: true },
    _count: { id: true },
  });

  const giftsSent = await prisma.giftEvent.aggregate({
    where: { senderId: userId },
    _sum: { coinCost: true },
  });

  const approvedPayments = await prisma.cfcPaymentRequest.aggregate({
    where: { userId, status: "approved" },
    _sum: { amount: true },
    _count: { id: true },
  });

  return ok(res, {
    liveStreams: streams.length,
    likes: posts._sum.likesCount ?? 0,
    postViews: posts._sum.viewCount ?? 0,
    postCount: posts._count.id,
    followers: user.followerCount,
    following: user.followingCount,
    giftsReceivedCount: giftsReceived._count.id,
    giftsReceivedCoins: giftsReceived._sum.coinCost ?? 0,
    giftsSentCoins: giftsSent._sum.coinCost ?? 0,
    approvedTopUpTotal: approvedPayments._sum.amount ?? 0,
    earningsJeton: giftsReceived._sum.coinCost ?? 0,
  });
});

profileExtrasRouter.get("/me/gifts-received", requireAuth, async (req, res) => {
  const userId = req.userId!;
  const rows = await prisma.giftEvent.findMany({
    where: { receiverId: userId },
    orderBy: { createdAt: "desc" },
    take: 80,
    include: { gift: true },
  });

  const grouped = new Map<
    string,
    { giftSlug: string; name: string; icon: string; count: number; coins: number }
  >();
  for (const e of rows) {
    const key = e.gift.slug;
    const prev = grouped.get(key);
    if (prev) {
      prev.count += e.quantity;
      prev.coins += e.coinCost;
    } else {
      grouped.set(key, {
        giftSlug: e.gift.slug,
        name: e.gift.name,
        icon: e.gift.icon,
        count: e.quantity,
        coins: e.coinCost,
      });
    }
  }

  return ok(res, {
    items: rows.map((e) => ({
      id: e.id,
      giftName: e.gift.name,
      icon: e.gift.icon,
      quantity: e.quantity,
      coinCost: e.coinCost,
      senderName: e.senderName,
      streamId: e.streamId,
      roomId: e.roomId,
      createdAt: e.createdAt.toISOString(),
    })),
    summary: [...grouped.values()].sort((a, b) => b.count - a.count),
  });
});

profileExtrasRouter.get("/me/broadcast-history", requireAuth, getBroadcastHistory);
profileExtrasRouter.get("/me/activity", requireAuth, getActivity);
profileExtrasRouter.patch("/me/activity", requireAuth, patchActivityMarkAllRead);

profileExtrasRouter.get("/:userId/followers", async (req, res) => {
  const rows = await prisma.follow.findMany({
    where: { followingId: req.params.userId },
    orderBy: { createdAt: "desc" },
    take: 80,
    include: {
      follower: {
        select: {
          id: true,
          username: true,
          displayName: true,
          avatarUrl: true,
          bio: true,
          followerCount: true,
        },
      },
    },
  });
  return ok(res, {
    users: rows.map((r) => publicUserPayload(r.follower)),
  });
});

profileExtrasRouter.get("/:userId/following", async (req, res) => {
  const rows = await prisma.follow.findMany({
    where: { followerId: req.params.userId },
    orderBy: { createdAt: "desc" },
    take: 80,
    include: {
      following: {
        select: {
          id: true,
          username: true,
          displayName: true,
          avatarUrl: true,
          bio: true,
          followerCount: true,
        },
      },
    },
  });
  return ok(res, {
    users: rows.map((r) => publicUserPayload(r.following)),
  });
});
