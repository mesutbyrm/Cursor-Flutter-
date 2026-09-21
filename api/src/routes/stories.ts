import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import requireAuth from '../middleware/requireAuth';

const router = Router();
const prisma = new PrismaClient();

interface StoryResponse {
  ok: boolean;
  data?: any;
  error?: string;
}

// Feature 29: Stories System
class StoriesService {
  async createStory(userId: string, content: string, mediaUrl?: string, mediaType?: string) {
    return prisma.userStory.create({
      data: {
        userId,
        content,
        mediaUrl,
        mediaType,
        expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
      },
      include: { user: { select: { id: true, displayName: true, avatarUrl: true } } },
    });
  }

  async getActiveStories(userId: string) {
    const now = new Date();
    return prisma.userStory.findMany({
      where: {
        user: {
          OR: [
            { userFollowersRel: { some: { followerId: userId } } },
          ],
        },
        expiresAt: { gt: now },
      },
      include: {
        user: { select: { id: true, displayName: true, avatarUrl: true } },
        reactions: { select: { emoji: true, userId: true } },
        views: { select: { userId: true, viewedAt: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getFollowingStories(userId: string) {
    const now = new Date();
    return prisma.userStory.findMany({
      where: {
        user: {
          userFollowersRel: { some: { followerId: userId } },
        },
        expiresAt: { gt: now },
      },
      include: {
        user: { select: { id: true, displayName: true, avatarUrl: true } },
        reactions: { select: { emoji: true, userId: true } },
        views: { select: { userId: true, viewedAt: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async viewStory(storyId: string, userId: string) {
    const existingView = await prisma.storyView.findUnique({
      where: { storyId_userId: { storyId, userId } },
    });

    if (!existingView) {
      await prisma.userStory.update({
        where: { id: storyId },
        data: { viewCount: { increment: 1 } },
      });

      await prisma.storyView.create({
        data: { storyId, userId, viewedAt: new Date() },
      });
    }

    return prisma.userStory.findUnique({
      where: { id: storyId },
      include: {
        views: { select: { userId: true, viewedAt: true } },
        reactions: { select: { emoji: true, userId: true } },
      },
    });
  }

  async getStoryViews(storyId: string) {
    return prisma.storyView.findMany({
      where: { storyId },
      include: { user: { select: { id: true, displayName: true, avatarUrl: true } } },
      orderBy: { viewedAt: 'desc' },
    });
  }

  async reactToStory(storyId: string, userId: string, emoji: string) {
    return prisma.storyReaction.upsert({
      where: { storyId_userId: { storyId, userId } },
      update: { emoji },
      create: { storyId, userId, emoji },
    });
  }

  async getStoryReactions(storyId: string) {
    return prisma.storyReaction.findMany({
      where: { storyId },
      include: { user: { select: { id: true, displayName: true, avatarUrl: true } } },
    });
  }

  async deleteStory(storyId: string) {
    await prisma.storyReaction.deleteMany({ where: { storyId } });
    await prisma.storyView.deleteMany({ where: { storyId } });
    return prisma.userStory.delete({ where: { id: storyId } });
  }

  async getUserStories(userId: string) {
    const now = new Date();
    return prisma.userStory.findMany({
      where: {
        userId,
        expiresAt: { gt: now },
      },
      include: {
        reactions: { select: { emoji: true, userId: true } },
        views: { select: { userId: true, viewedAt: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }
}

const service = new StoriesService();

router.post('/create', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const { content, mediaUrl, mediaType } = req.body as {
      content: string;
      mediaUrl?: string;
      mediaType?: string;
    };

    if (!content && !mediaUrl) {
      return res.status(400).json({
        ok: false,
        error: 'Hikaye içeriği veya medya gereklidir',
      } as StoryResponse);
    }

    const story = await service.createStory(userId, content, mediaUrl, mediaType);

    res.json({
      ok: true,
      data: story,
    } as StoryResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as StoryResponse);
  }
});

router.get('/active', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;

    const stories = await service.getActiveStories(userId);

    res.json({
      ok: true,
      data: { stories },
    } as StoryResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as StoryResponse);
  }
});

router.get('/following', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;

    const stories = await service.getFollowingStories(userId);

    res.json({
      ok: true,
      data: { stories },
    } as StoryResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as StoryResponse);
  }
});

router.get('/user/:userId', requireAuth, async (req, res) => {
  try {
    const { userId } = req.params;

    const stories = await service.getUserStories(userId);

    res.json({
      ok: true,
      data: { stories },
    } as StoryResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as StoryResponse);
  }
});

router.post('/:storyId/view', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const { storyId } = req.params;

    const story = await service.viewStory(storyId, userId);

    res.json({
      ok: true,
      data: story,
    } as StoryResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as StoryResponse);
  }
});

router.get('/:storyId/views', requireAuth, async (req, res) => {
  try {
    const { storyId } = req.params;

    const views = await service.getStoryViews(storyId);

    res.json({
      ok: true,
      data: { views },
    } as StoryResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as StoryResponse);
  }
});

router.post('/:storyId/react', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const { storyId } = req.params;
    const { emoji } = req.body as { emoji: string };

    if (!emoji) {
      return res.status(400).json({
        ok: false,
        error: 'Emoji gereklidir',
      } as StoryResponse);
    }

    const reaction = await service.reactToStory(storyId, userId, emoji);

    res.json({
      ok: true,
      data: reaction,
    } as StoryResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as StoryResponse);
  }
});

router.get('/:storyId/reactions', requireAuth, async (req, res) => {
  try {
    const { storyId } = req.params;

    const reactions = await service.getStoryReactions(storyId);

    res.json({
      ok: true,
      data: { reactions },
    } as StoryResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as StoryResponse);
  }
});

router.delete('/:storyId', requireAuth, async (req, res) => {
  try {
    const { storyId } = req.params;

    await service.deleteStory(storyId);

    res.json({
      ok: true,
      data: { id: storyId },
    } as StoryResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as StoryResponse);
  }
});

export default router;
