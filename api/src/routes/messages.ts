import { Router } from "express";
import { prisma } from "../lib/prisma";
import { notifyDirectMessage } from "../lib/push_events";
import { ok } from "../lib/response";
import { requireAuth } from "../middleware/requireAuth";

export const messagesRouter = Router();

function conversationPayload(c: {
  id: string;
  title: string;
  lastMessage: string | null;
  unreadCount: number;
  peerAvatarUrl: string | null;
}) {
  return {
    id: c.id,
    title: c.title,
    subtitle: c.lastMessage,
    lastMessage: c.lastMessage,
    unreadCount: c.unreadCount,
    peer: { avatarUrl: c.peerAvatarUrl },
  };
}

/** POST /api/messages/conversations — yeni sohbet veya mevcut thread */
messagesRouter.post("/conversations", requireAuth, async (req, res) => {
  const userId = req.userId!;
  const recipientId =
    (req.body?.recipientId as string | undefined) ??
    (req.body?.userId as string | undefined);
  if (!recipientId?.trim() || recipientId === userId) {
    return res.status(400).json({
      success: false,
      error: "Geçersiz alıcı",
    });
  }

  const recipient = await prisma.user.findUnique({
    where: { id: recipientId.trim() },
    select: { id: true, displayName: true, username: true, avatarUrl: true },
  });
  if (!recipient) {
    return res.status(404).json({ success: false, error: "Kullanıcı bulunamadı" });
  }

  const [userAId, userBId] =
    userId < recipient.id
      ? [userId, recipient.id]
      : [recipient.id, userId];

  let conv = await prisma.conversation.findFirst({
    where: { userAId, userBId },
  });

  if (!conv) {
    conv = await prisma.conversation.create({
      data: { userAId, userBId },
    });
  }

  return res.status(200).json({
    id: conv.id,
    conversationId: conv.id,
    title: recipient.displayName ?? recipient.username ?? "Sohbet",
    peer: { avatarUrl: recipient.avatarUrl },
    unreadCount: conv.userAId === userId ? conv.unreadForA : conv.unreadForB,
  });
});

/** GET /api/messages/conversations */
messagesRouter.get("/conversations", requireAuth, async (req, res) => {
  const userId = req.userId!;
  const rows = await prisma.conversation.findMany({
    where: {
      OR: [{ userAId: userId }, { userBId: userId }],
    },
    orderBy: { updatedAt: "desc" },
    take: 60,
    include: {
      userA: { select: { id: true, displayName: true, username: true, avatarUrl: true } },
      userB: { select: { id: true, displayName: true, username: true, avatarUrl: true } },
    },
  });

  const items = rows.map((row) => {
    const peer = row.userAId === userId ? row.userB : row.userA;
    const unread =
      row.userAId === userId ? row.unreadForA : row.unreadForB;
    return conversationPayload({
      id: row.id,
      title: peer.displayName ?? peer.username ?? "Sohbet",
      lastMessage: row.lastMessage,
      unreadCount: unread,
      peerAvatarUrl: peer.avatarUrl,
    });
  });

  return res.status(200).json({ items, conversations: items, data: items });
});

/** GET /api/messages/conversations/:id/messages */
messagesRouter.get("/conversations/:id/messages", requireAuth, async (req, res) => {
  const userId = req.userId!;
  const conv = await prisma.conversation.findFirst({
    where: {
      id: req.params.id,
      OR: [{ userAId: userId }, { userBId: userId }],
    },
  });
  if (!conv) {
    return res.status(404).json({ success: false, error: "Sohbet bulunamadı" });
  }

  const rows = await prisma.directMessage.findMany({
    where: { conversationId: conv.id },
    orderBy: { createdAt: "asc" },
    take: 200,
  });

  const items = rows.map((m) => ({
    id: m.id,
    text: m.text,
    content: m.text,
    senderId: m.senderId,
    isMine: m.senderId === userId,
    createdAt: m.createdAt.toISOString(),
  }));

  if (conv.userAId === userId) {
    await prisma.conversation.update({
      where: { id: conv.id },
      data: { unreadForA: 0 },
    });
  } else {
    await prisma.conversation.update({
      where: { id: conv.id },
      data: { unreadForB: 0 },
    });
  }

  return res.status(200).json({ items, messages: items, data: items });
});

/** POST /api/messages/conversations/:id/messages */
messagesRouter.post("/conversations/:id/messages", requireAuth, async (req, res) => {
  const userId = req.userId!;
  const text =
    (req.body?.text as string | undefined) ??
    (req.body?.content as string | undefined);
  if (!text?.trim()) {
    return res.status(400).json({ success: false, error: "Mesaj boş olamaz" });
  }

  const conv = await prisma.conversation.findFirst({
    where: {
      id: req.params.id,
      OR: [{ userAId: userId }, { userBId: userId }],
    },
    include: {
      userA: { select: { id: true, displayName: true, username: true } },
      userB: { select: { id: true, displayName: true, username: true } },
    },
  });
  if (!conv) {
    return res.status(404).json({ success: false, error: "Sohbet bulunamadı" });
  }

  const msg = await prisma.directMessage.create({
    data: {
      conversationId: conv.id,
      senderId: userId,
      text: text.trim(),
    },
  });

  await prisma.conversation.update({
    where: { id: conv.id },
    data: {
      lastMessage: text.trim(),
      updatedAt: new Date(),
      ...(conv.userAId === userId
        ? { unreadForB: { increment: 1 } }
        : { unreadForA: { increment: 1 } }),
    },
  });

  const recipientId =
    conv.userAId === userId ? conv.userBId : conv.userAId;
  const sender = conv.userAId === userId ? conv.userA : conv.userB;
  const senderLabel =
    sender.displayName ?? sender.username ?? "Bir kullanıcı";

  void notifyDirectMessage({
    conversationId: conv.id,
    senderId: userId,
    recipientId,
    preview: text.trim(),
    senderLabel,
  });

  return ok(res, {
    id: msg.id,
    text: msg.text,
    senderId: msg.senderId,
    createdAt: msg.createdAt.toISOString(),
  });
});
