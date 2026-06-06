import { Router } from "express";
import { z } from "zod";
import { prisma } from "../lib/prisma";
import { fail, ok } from "../lib/response";
import { optionalAuth } from "../middleware/optionalAuth";
import { applyPkGift } from "../lib/pkBattleService";
import {
  emitGiftEvent,
  emitGiftRoomEvent,
  emitPkBattleEvent,
} from "../socket/giftHub";

const platformSchema = z.enum(["mobile", "web", "all"]).optional();

function giftPayload(g: {
  id: string;
  slug: string;
  name: string;
  icon: string;
  animation: string | null;
  animationType: string;
  price: number;
  rarity: string;
  platform: string;
  sound: string | null;
  sortOrder: number;
}) {
  return {
    id: g.slug,
    slug: g.slug,
    giftTypeId: g.slug,
    name: g.name,
    nameTr: g.name,
    icon: g.icon,
    iconUrl: g.icon,
    animation: g.animation,
    animationKey: g.animation ?? g.slug,
    animationType: g.animationType,
    price: g.price,
    rarity: g.rarity,
    platform: g.platform,
    sound: g.sound,
    sortOrder: g.sortOrder,
  };
}

function eventPayload(e: {
  id: string;
  senderId: string | null;
  senderName: string;
  receiverId: string | null;
  receiverName: string;
  quantity: number;
  coinCost: number;
  combo: number;
  createdAt: Date;
  gift: {
    slug: string;
    name: string;
    icon: string;
    animation: string | null;
    animationType: string;
    rarity: string;
    sound: string | null;
  };
}) {
  return {
    id: e.id,
    senderId: e.senderId,
    senderName: e.senderName,
    receiverId: e.receiverId,
    receiverName: e.receiverName,
    giftTypeId: e.gift.slug,
    giftId: e.gift.slug,
    giftName: e.gift.name,
    giftTypeName: e.gift.name,
    quantity: e.quantity,
    count: e.quantity,
    price: e.coinCost,
    coinCost: e.coinCost,
    combo: e.combo,
    comboCount: e.combo,
    icon: e.gift.icon,
    iconUrl: e.gift.icon,
    animation: e.gift.animation,
    animationKey: e.gift.animation ?? e.gift.slug,
    animationType: e.gift.animationType,
    rarity: e.gift.rarity,
    sound: e.gift.sound,
    createdAt: e.createdAt.toISOString(),
    timestamp: e.createdAt.toISOString(),
  };
}

export const giftsRouter = Router();

/** GET /api/gifts?platform=mobile|web */
giftsRouter.get("/", async (req, res) => {
  const platform = platformSchema.parse(req.query.platform) ?? "mobile";
  const rows = await prisma.gift.findMany({
    where: {
      enabled: true,
      OR: [{ platform: "all" }, { platform }],
    },
    orderBy: [{ sortOrder: "asc" }, { price: "asc" }],
  });
  return ok(res, rows.map(giftPayload));
});

const sendSchema = z.object({
  giftTypeId: z.string().min(1),
  quantity: z.coerce.number().int().min(1).max(999).default(1),
  senderName: z.string().max(64).optional(),
  receiverName: z.string().max(64).optional(),
  platform: z.enum(["mobile", "web"]).default("mobile"),
});

/** POST /api/video-streams/:streamId/gifts */
export async function sendStreamGift(
  streamId: string,
  body: unknown,
  userId: string | undefined,
  res: import("express").Response,
) {
  const parsed = sendSchema.safeParse(body);
  if (!parsed.success) {
    return fail(res, 400, "VALIDATION_ERROR", "Geçersiz hediye", parsed.error.flatten());
  }
  const { giftTypeId, quantity, senderName, receiverName, platform } = parsed.data;

  const gift = await prisma.gift.findFirst({
    where: {
      enabled: true,
      AND: [
        { OR: [{ slug: giftTypeId }, { id: giftTypeId }] },
        { OR: [{ platform: "all" }, { platform }] },
      ],
    },
  });
  if (!gift) {
    return fail(res, 404, "GIFT_NOT_FOUND", "Hediye bulunamadı");
  }

  const totalCost = gift.price * quantity;
  let newBalance: number | undefined;

  if (userId) {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) return fail(res, 401, "UNAUTHORIZED", "Kullanıcı bulunamadı");
    if (user.coins < totalCost) {
      return fail(res, 402, "INSUFFICIENT_COINS", "Yetersiz jeton");
    }
    const updated = await prisma.user.update({
      where: { id: userId },
      data: { coins: { decrement: totalCost } },
    });
    newBalance = updated.coins;
  }

  const combo = await resolveCombo(streamId, userId, gift.id, quantity);

  let receiverId: string | null = null;
  if (receiverName && receiverName !== "Yayıncı") {
    const recv = await prisma.user.findFirst({
      where: {
        OR: [
          { username: receiverName.replace(/^@/, "") },
          { displayName: receiverName },
        ],
      },
      select: { id: true },
    });
    receiverId = recv?.id ?? null;
  }

  const event = await prisma.giftEvent.create({
    data: {
      giftId: gift.id,
      senderId: userId ?? null,
      senderName: senderName ?? "Misafir",
      receiverId,
      receiverName: receiverName ?? "Yayıncı",
      streamId,
      quantity,
      coinCost: totalCost,
      combo,
      platform,
    },
    include: { gift: true },
  });

  const payload = eventPayload(event);
  emitGiftEvent(streamId, payload);

  const pkResult = await applyPkGift({
    streamId,
    giftEventId: event.id,
    senderId: userId ?? null,
    senderName: event.senderName,
    giftSlug: gift.slug,
    giftName: gift.name,
    quantity,
    coinPrice: gift.price,
  });
  if (pkResult) {
    for (const ev of pkResult.events) {
      emitPkBattleEvent(pkResult.battle, ev, { gift: pkResult.gift });
    }
  }

  return res.status(200).json({
    ...payload,
    newBalance,
    balance: newBalance,
    coinBalance: newBalance,
    streamerBalance: totalCost,
    pkBattle: pkResult?.battle ?? null,
  });
}

/** GET /api/video-streams/:streamId/gifts */
export async function listStreamGiftEvents(
  streamId: string,
  since: string | undefined,
  res: import("express").Response,
) {
  const sinceDate = since ? new Date(since) : new Date(Date.now() - 120_000);
  const rows = await prisma.giftEvent.findMany({
    where: {
      streamId,
      createdAt: { gte: sinceDate },
    },
    orderBy: { createdAt: "asc" },
    take: 100,
    include: { gift: true },
  });
  return ok(res, rows.map(eventPayload));
}

/** GET /api/video-streams/:streamId/gifts/leaderboard */
export async function streamGiftLeaderboard(
  streamId: string,
  res: import("express").Response,
) {
  const since = new Date(Date.now() - 24 * 60 * 60 * 1000);
  const grouped = await prisma.giftEvent.groupBy({
    by: ["senderId", "senderName"],
    where: {
      streamId,
      createdAt: { gte: since },
      senderId: { not: null },
    },
    _sum: { coinCost: true, quantity: true },
    orderBy: { _sum: { coinCost: "desc" } },
    take: 20,
  });

  const leaders = grouped.map((g: (typeof grouped)[number], i: number) => ({
    rank: i + 1,
    userId: g.senderId,
    displayName: g.senderName,
    totalCoins: g._sum.coinCost ?? 0,
    giftCount: g._sum.quantity ?? 0,
  }));

  return ok(res, { leaders, streamId });
}

async function resolveComboRoom(
  roomId: string,
  senderId: string | undefined,
  giftId: string,
  quantity: number,
): Promise<number> {
  if (!senderId) return quantity;
  const windowStart = new Date(Date.now() - 4000);
  const recent = await prisma.giftEvent.findFirst({
    where: {
      roomId,
      senderId,
      giftId,
      createdAt: { gte: windowStart },
    },
    orderBy: { createdAt: "desc" },
  });
  if (!recent) return quantity;
  return recent.combo + quantity;
}

/** POST /api/chat/rooms/:roomId/gifts — sesli sohbet odası hediyesi */
export async function sendRoomGift(
  roomId: string,
  body: unknown,
  userId: string | undefined,
  res: import("express").Response,
) {
  const parsed = sendSchema.safeParse(body);
  if (!parsed.success) {
    return fail(res, 400, "VALIDATION_ERROR", "Geçersiz hediye", parsed.error.flatten());
  }
  const { giftTypeId, quantity, senderName, receiverName, platform } = parsed.data;

  const gift = await prisma.gift.findFirst({
    where: {
      enabled: true,
      AND: [
        { OR: [{ slug: giftTypeId }, { id: giftTypeId }] },
        { OR: [{ platform: "all" }, { platform }] },
      ],
    },
  });
  if (!gift) {
    return fail(res, 404, "GIFT_NOT_FOUND", "Hediye bulunamadı");
  }

  const totalCost = gift.price * quantity;
  let newBalance: number | undefined;

  if (userId) {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) return fail(res, 401, "UNAUTHORIZED", "Kullanıcı bulunamadı");
    if (user.coins < totalCost) {
      return fail(res, 402, "INSUFFICIENT_COINS", "Yetersiz jeton");
    }
    const updated = await prisma.user.update({
      where: { id: userId },
      data: { coins: { decrement: totalCost } },
    });
    newBalance = updated.coins;
  }

  const combo = await resolveComboRoom(roomId, userId, gift.id, quantity);

  let receiverId: string | null = null;
  if (receiverName && receiverName !== "Yayıncı") {
    const recv = await prisma.user.findFirst({
      where: {
        OR: [
          { username: receiverName.replace(/^@/, "") },
          { displayName: receiverName },
        ],
      },
      select: { id: true },
    });
    receiverId = recv?.id ?? null;
  }

  const event = await prisma.giftEvent.create({
    data: {
      giftId: gift.id,
      senderId: userId ?? null,
      senderName: senderName ?? "Misafir",
      receiverId,
      receiverName: receiverName ?? "Yayıncı",
      roomId,
      quantity,
      coinCost: totalCost,
      combo,
      platform,
    },
    include: { gift: true },
  });

  const payload = eventPayload(event);
  emitGiftRoomEvent(roomId, payload);

  const pkResult = await applyPkGift({
    roomId,
    giftEventId: event.id,
    senderId: userId ?? null,
    senderName: event.senderName,
    giftSlug: gift.slug,
    giftName: gift.name,
    quantity,
    coinPrice: gift.price,
  });
  if (pkResult) {
    for (const ev of pkResult.events) {
      emitPkBattleEvent(pkResult.battle, ev, { gift: pkResult.gift });
    }
  }

  return res.status(200).json({
    ...payload,
    newBalance,
    balance: newBalance,
    coinBalance: newBalance,
    pkBattle: pkResult?.battle ?? null,
  });
}

/** GET /api/chat/rooms/:roomId/gifts */
export async function listRoomGiftEvents(
  roomId: string,
  since: string | undefined,
  res: import("express").Response,
) {
  const sinceDate = since ? new Date(since) : new Date(Date.now() - 120_000);
  const rows = await prisma.giftEvent.findMany({
    where: {
      roomId,
      createdAt: { gte: sinceDate },
    },
    orderBy: { createdAt: "asc" },
    take: 100,
    include: { gift: true },
  });
  return ok(res, rows.map(eventPayload));
}

async function resolveCombo(
  streamId: string,
  senderId: string | undefined,
  giftId: string,
  quantity: number,
): Promise<number> {
  if (!senderId) return quantity;
  const windowStart = new Date(Date.now() - 4000);
  const recent = await prisma.giftEvent.findFirst({
    where: {
      streamId,
      senderId,
      giftId,
      createdAt: { gte: windowStart },
    },
    orderBy: { createdAt: "desc" },
  });
  if (!recent) return quantity;
  return recent.combo + quantity;
}

export const videoStreamGiftsRouter = Router();

videoStreamGiftsRouter.get("/gifts", async (req, res) => {
  const platform = platformSchema.parse(req.query.platform) ?? "mobile";
  const rows = await prisma.gift.findMany({
    where: {
      enabled: true,
      OR: [{ platform: "all" }, { platform }],
    },
    orderBy: [{ sortOrder: "asc" }, { price: "asc" }],
  });
  return res.status(200).json(rows.map(giftPayload));
});

videoStreamGiftsRouter.get("/:streamId/gifts/leaderboard", async (req, res) => {
  return streamGiftLeaderboard(req.params.streamId, res);
});

videoStreamGiftsRouter.get("/:streamId/gifts", async (req, res) => {
  const since = req.query.since as string | undefined;
  const rows = await prisma.giftEvent.findMany({
    where: {
      streamId: req.params.streamId,
      ...(since ? { createdAt: { gte: new Date(since) } } : {}),
    },
    orderBy: { createdAt: "asc" },
    take: 100,
    include: { gift: true },
  });
  return res.status(200).json(rows.map(eventPayload));
});

videoStreamGiftsRouter.post(
  "/:streamId/gifts",
  optionalAuth,
  async (req, res) => {
    return sendStreamGift(req.params.streamId, req.body, req.userId, res);
  },
);
