import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import requireAuth from '../middleware/requireAuth';

const router = Router();
const prisma = new PrismaClient();

interface DMResponse {
  ok: boolean;
  data?: any;
  error?: string;
}

class DirectMessageService {
  async getOrCreateConversation(userId1: string, userId2: string) {
    const [user1Id, user2Id] = [userId1, userId2].sort();

    return prisma.directMessageConversation.upsert({
      where: {
        participant1Id_participant2Id: { participant1Id: user1Id, participant2Id: user2Id },
      },
      update: { updatedAt: new Date() },
      create: { participant1Id: user1Id, participant2Id: user2Id },
      include: { messages: { orderBy: { createdAt: 'desc' }, take: 10 } },
    });
  }

  async sendMessage(
    conversationId: string,
    senderId: string,
    content: string,
    mediaUrl?: string,
    mediaType?: string,
  ) {
    const message = await prisma.directMessage.create({
      data: {
        conversationId,
        senderId,
        content,
        mediaUrl,
        mediaType,
      },
    });

    await prisma.directMessageConversation.update({
      where: { id: conversationId },
      data: {
        lastMessage: content,
        lastMessageAt: new Date(),
      },
    });

    return message;
  }

  async getConversationMessages(conversationId: string, limit: number = 50, offset: number = 0) {
    return prisma.directMessage.findMany({
      where: { conversationId },
      include: { sender: { select: { id: true, displayName: true, avatarUrl: true } } },
      orderBy: { createdAt: 'desc' },
      take: limit,
      skip: offset,
    });
  }

  async getConversations(userId: string) {
    return prisma.directMessageConversation.findMany({
      where: {
        OR: [{ participant1Id: userId }, { participant2Id: userId }],
      },
      include: {
        participant1: { select: { id: true, displayName: true, avatarUrl: true } },
        participant2: { select: { id: true, displayName: true, avatarUrl: true } },
        messages: { orderBy: { createdAt: 'desc' }, take: 1 },
      },
      orderBy: { lastMessageAt: 'desc' },
    });
  }

  async markAsRead(messageId: string) {
    return prisma.directMessage.update({
      where: { id: messageId },
      data: { read: true, readAt: new Date() },
    });
  }

  async deleteMessage(messageId: string) {
    return prisma.directMessage.delete({
      where: { id: messageId },
    });
  }

  async getUnreadCount(userId: string) {
    return prisma.directMessage.count({
      where: {
        conversation: {
          OR: [{ participant1Id: userId }, { participant2Id: userId }],
        },
        read: false,
        senderId: { not: userId },
      },
    });
  }
}

const service = new DirectMessageService();

router.post('/conversations/:userId/start', requireAuth, async (req, res) => {
  try {
    const currentUserId = req.userId!;
    const { userId } = req.params;

    const conversation = await service.getOrCreateConversation(currentUserId, userId);

    res.json({
      ok: true,
      data: conversation,
    } as DMResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as DMResponse);
  }
});

router.get('/conversations', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;

    const conversations = await service.getConversations(userId);

    res.json({
      ok: true,
      data: { conversations },
    } as DMResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as DMResponse);
  }
});

router.post('/conversations/:conversationId/messages', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const { conversationId } = req.params;
    const { content, mediaUrl, mediaType } = req.body as {
      content: string;
      mediaUrl?: string;
      mediaType?: string;
    };

    if (!content && !mediaUrl) {
      return res.status(400).json({
        ok: false,
        error: 'Message content or media is required',
      } as DMResponse);
    }

    const message = await service.sendMessage(conversationId, userId, content, mediaUrl, mediaType);

    res.json({
      ok: true,
      data: message,
    } as DMResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as DMResponse);
  }
});

router.get('/conversations/:conversationId/messages', requireAuth, async (req, res) => {
  try {
    const { conversationId } = req.params;
    const limit = parseInt(req.query.limit as string) || 50;
    const offset = parseInt(req.query.offset as string) || 0;

    const messages = await service.getConversationMessages(conversationId, limit, offset);

    res.json({
      ok: true,
      data: { messages },
    } as DMResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as DMResponse);
  }
});

router.put('/messages/:messageId/read', requireAuth, async (req, res) => {
  try {
    const { messageId } = req.params;

    const message = await service.markAsRead(messageId);

    res.json({
      ok: true,
      data: message,
    } as DMResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as DMResponse);
  }
});

router.delete('/messages/:messageId', requireAuth, async (req, res) => {
  try {
    const { messageId } = req.params;

    await service.deleteMessage(messageId);

    res.json({
      ok: true,
      data: { id: messageId },
    } as DMResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as DMResponse);
  }
});

router.get('/unread-count', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;

    const count = await service.getUnreadCount(userId);

    res.json({
      ok: true,
      data: { unreadCount: count },
    } as DMResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as DMResponse);
  }
});

export default router;
