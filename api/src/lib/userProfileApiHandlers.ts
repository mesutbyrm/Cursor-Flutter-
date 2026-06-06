import type { Request, Response } from "express";
import { prisma } from "./prisma";
import { ok } from "./response";

function parsePageLimit(req: Request, defaultLimit = 20) {
  const page = Math.max(1, Number(req.query.page) || 1);
  const limit = Math.min(50, Math.max(1, Number(req.query.limit) || defaultLimit));
  return { page, limit, skip: (page - 1) * limit };
}

/** GET broadcast history — Flutter: /api/user/broadcast-history */
export async function getBroadcastHistory(req: Request, res: Response) {
  const userId = req.userId!;
  const { page, limit, skip } = parsePageLimit(req, 20);
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

  const allItems = [...byStream.values()]
    .sort((a, b) => b.startedAt.localeCompare(a.startedAt))
    .map((s, i) => ({
      id: s.streamId,
      title: `Canlı yayın #${i + 1}`,
      streamId: s.streamId,
      startedAt: s.startedAt,
      giftCount: s.giftCount,
      coinsEarned: s.coins,
      status: "ended",
    }));

  const total = allItems.length;
  const items = allItems.slice(skip, skip + limit);
  const totalPages = Math.max(1, Math.ceil(total / limit));

  return ok(res, {
    items,
    pagination: { page, limit, total, totalPages },
  });
}

/** GET activity — Flutter: /api/user/activity?unread=true */
export async function getActivity(req: Request, res: Response) {
  const userId = req.userId!;
  const { page, limit, skip } = parsePageLimit(req, 30);
  const unreadOnly =
    req.query.unread === "true" || req.query.unreadOnly === "true";

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

  const notifRows = await prisma.appNotification.findMany({
    where: { OR: [{ userId }, { userId: null }] },
    orderBy: { createdAt: "desc" },
    take: 40,
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
      read: p.status === "approved",
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
      subtitle: g.streamId
        ? `Yayın ${g.streamId}`
        : g.roomId
          ? `Oda ${g.roomId}`
          : "",
      status: "completed",
      read: true,
      amount: g.coinCost,
      createdAt: g.createdAt.toISOString(),
    })),
    ...notifRows.map((n) => ({
      id: n.id,
      type: n.type,
      title: n.title,
      subtitle: n.body ?? "",
      status: n.read ? "read" : "unread",
      read: n.read,
      amount: 0,
      createdAt: n.createdAt.toISOString(),
    })),
  ].sort((a, b) => b.createdAt.localeCompare(a.createdAt));

  let filtered = items;
  if (unreadOnly) {
    filtered = filtered.filter((i) => !i.read && i.status !== "read");
  }

  const total = filtered.length;
  const pageItems = filtered.slice(skip, skip + limit);
  const totalPages = Math.max(1, Math.ceil(total / limit));

  return ok(res, {
    items: pageItems,
    activities: pageItems,
    pagination: { page, limit, total, totalPages },
  });
}

/** PATCH activity — Flutter: {"markAllRead": true} */
export async function patchActivityMarkAllRead(req: Request, res: Response) {
  const userId = req.userId!;
  const body = req.body as { markAllRead?: boolean };
  if (body?.markAllRead !== true) {
    return ok(res, { markAllRead: false, message: "markAllRead: true gerekli" });
  }

  await prisma.appNotification.updateMany({
    where: { userId },
    data: { read: true },
  });

  return ok(res, { markAllRead: true, success: true });
}
