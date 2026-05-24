import { Router } from "express";
import { prisma } from "../lib/prisma";
import { fail, ok } from "../lib/response";
import { requireAuth } from "../middleware/requireAuth";
import { publicUserPayload } from "../lib/auth_user";

export const profileExtrasRouter = Router();

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

profileExtrasRouter.get("/me/broadcast-history", requireAuth, async (req, res) => {
  const userId = req.userId!;
  const events = await prisma.giftEvent.findMany({
    where: {
      streamId: { not: null },
      OR: [{ receiverId: userId }, { senderId: userId }],
    },
    orderBy: { createdAt: "desc" },
    take: 200,
    select: {
      streamId: true,
      createdAt: true,
      coinCost: true,
      quantity: true,
    },
  });

  const byStream = new Map<
    string,
    { streamId: string; startedAt: string; giftCount: number; coins: number }
  >();
  for (const e of events) {
    const sid = e.streamId!;
    const prev = byStream.get(sid);
    if (prev) {
      prev.giftCount += e.quantity;
      prev.coins += e.coinCost;
      if (e.createdAt.toISOString() < prev.startedAt) {
        prev.startedAt = e.createdAt.toISOString();
      }
    } else {
      byStream.set(sid, {
        streamId: sid,
        startedAt: e.createdAt.toISOString(),
        giftCount: e.quantity,
        coins: e.coinCost,
      });
    }
  }

  const items = [...byStream.values()]
    .sort((a, b) => b.startedAt.localeCompare(a.startedAt))
    .slice(0, 40)
    .map((s, i) => ({
      id: s.streamId,
      title: `Canlı yayın #${40 - i}`,
      streamId: s.streamId,
      startedAt: s.startedAt,
      giftCount: s.giftCount,
      coinsEarned: s.coins,
    }));

  return ok(res, { items });
});

profileExtrasRouter.get("/me/activity", requireAuth, async (req, res) => {
  const userId = req.userId!;
  const payments = await prisma.cfcPaymentRequest.findMany({
    where: { userId },
    orderBy: { createdAt: "desc" },
    take: 40,
  });

  const gifts = await prisma.giftEvent.findMany({
    where: {
      OR: [{ senderId: userId }, { receiverId: userId }],
    },
    orderBy: { createdAt: "desc" },
    take: 40,
    include: { gift: true },
  });

  const items = [
    ...payments.map((p) => ({
      id: `pay-${p.id}`,
      type: p.requestType === "jeton" ? "jeton_payment" : "cfc_payment",
      title:
        p.requestType === "jeton"
          ? `Jeton yükleme (${p.amount})`
          : `CFC yükleme (${p.amount})`,
      subtitle: p.method,
      status: p.status,
      amount: p.amount,
      createdAt: p.createdAt.toISOString(),
    })),
    ...gifts.map((g) => ({
      id: `gift-${g.id}`,
      type: g.senderId === userId ? "gift_sent" : "gift_received",
      title:
        g.senderId === userId
          ? `Hediye gönderildi: ${g.gift.name}`
          : `Hediye alındı: ${g.gift.name}`,
      subtitle: g.streamId ? `Yayın ${g.streamId}` : g.roomId ? `Oda ${g.roomId}` : "",
      status: "completed",
      amount: g.coinCost,
      createdAt: g.createdAt.toISOString(),
    })),
  ].sort((a, b) => b.createdAt.localeCompare(a.createdAt));

  return ok(res, { items: items.slice(0, 60) });
});

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
