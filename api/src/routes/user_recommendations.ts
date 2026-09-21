import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import requireAuth from '../middleware/requireAuth';

const router = Router();
const prisma = new PrismaClient();

interface RecommendationResponse {
  ok: boolean;
  data?: any;
  error?: string;
}

// Feature 32: User Recommendations
class UserRecommendationService {
  async getRecommendations(userId: string, limit: number = 20, offset: number = 0) {
    return prisma.userRecommendation.findMany({
      where: { userId },
      include: {
        recommendedUser: {
          select: { id: true, displayName: true, avatarUrl: true, bio: true },
        },
      },
      orderBy: { score: 'desc' },
      take: limit,
      skip: offset,
    });
  }

  async createRecommendation(userId: string, recommendedUserId: string, reason: string, score: number) {
    if (userId === recommendedUserId) {
      throw new Error('Kendinize tavsiye oluşturmazsınız');
    }

    return prisma.userRecommendation.upsert({
      where: {
        userId_recommendedUserId: { userId, recommendedUserId },
      },
      update: { score, interactionCount: { increment: 1 } },
      create: { userId, recommendedUserId, reason, score, interactionCount: 1 },
      include: {
        recommendedUser: {
          select: { id: true, displayName: true, avatarUrl: true, bio: true },
        },
      },
    });
  }

  async deleteRecommendation(userId: string, recommendedUserId: string) {
    return prisma.userRecommendation.delete({
      where: {
        userId_recommendedUserId: { userId, recommendedUserId },
      },
    });
  }

  async getSimilarUsers(userId: string, limit: number = 10) {
    const userPreferences = await prisma.userPreferences.findUnique({
      where: { userId },
    });

    return prisma.userRecommendation.findMany({
      where: { userId },
      include: {
        recommendedUser: {
          select: { id: true, displayName: true, avatarUrl: true, bio: true },
        },
      },
      orderBy: [{ score: 'desc' }, { interactionCount: 'desc' }],
      take: limit,
    });
  }

  async incrementInteraction(userId: string, recommendedUserId: string) {
    return prisma.userRecommendation.update({
      where: {
        userId_recommendedUserId: { userId, recommendedUserId },
      },
      data: { interactionCount: { increment: 1 } },
    });
  }
}

const service = new UserRecommendationService();

router.get('/recommendations', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const limit = parseInt(req.query.limit as string) || 20;
    const offset = parseInt(req.query.offset as string) || 0;

    const recommendations = await service.getRecommendations(userId, limit, offset);

    res.json({
      ok: true,
      data: { recommendations },
    } as RecommendationResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as RecommendationResponse);
  }
});

router.post('/create', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const { recommendedUserId, reason, score } = req.body as {
      recommendedUserId: string;
      reason: string;
      score: number;
    };

    if (!recommendedUserId || !reason) {
      return res.status(400).json({
        ok: false,
        error: 'Tavsiye edilen kullanıcı ve neden gereklidir',
      } as RecommendationResponse);
    }

    const recommendation = await service.createRecommendation(
      userId,
      recommendedUserId,
      reason,
      score || 0.5
    );

    res.json({
      ok: true,
      data: recommendation,
    } as RecommendationResponse);
  } catch (error: any) {
    res.status(400).json({
      ok: false,
      error: error.message,
    } as RecommendationResponse);
  }
});

router.delete('/:recommendedUserId', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const { recommendedUserId } = req.params;

    await service.deleteRecommendation(userId, recommendedUserId);

    res.json({
      ok: true,
      data: { deleted: true },
    } as RecommendationResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as RecommendationResponse);
  }
});

router.get('/similar', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const limit = parseInt(req.query.limit as string) || 10;

    const similar = await service.getSimilarUsers(userId, limit);

    res.json({
      ok: true,
      data: { similar },
    } as RecommendationResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as RecommendationResponse);
  }
});

router.post('/:recommendedUserId/interact', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const { recommendedUserId } = req.params;

    const updated = await service.incrementInteraction(userId, recommendedUserId);

    res.json({
      ok: true,
      data: updated,
    } as RecommendationResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as RecommendationResponse);
  }
});

export default router;
