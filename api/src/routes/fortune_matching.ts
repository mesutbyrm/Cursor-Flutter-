import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import requireAuth from '../middleware/requireAuth';

const router = Router();
const prisma = new PrismaClient();

interface FortuneMatchResponse {
  ok: boolean;
  data?: any;
  error?: string;
}

class FortuneMatchingService {
  async calculateCompatibility(
    user1: any,
    user2: any,
    fortune1?: any,
    fortune2?: any,
  ): Promise<number> {
    let score = 50;

    if (fortune1?.type === fortune2?.type) {
      score += 15;
    }

    if (
      fortune1?.luckyNumber &&
      fortune2?.luckyNumber &&
      Math.abs(fortune1.luckyNumber - fortune2.luckyNumber) < 5
    ) {
      score += 10;
    }

    if (fortune1?.luckyColor === fortune2?.luckyColor) {
      score += 10;
    }

    const user1Bias = Math.random() * 10 - 5;
    score = Math.min(100, Math.max(0, score + user1Bias));

    return Math.round(score) / 100;
  }

  async generateInsights(
    user1Id: string,
    user2Id: string,
    compatibilityScore: number,
  ): Promise<{
    analysis: string;
    insights: Record<string, any>;
    recommendations: string[];
  }> {
    const analysis =
      compatibilityScore > 0.75
        ? 'Çok yüksek uyum! Bu kişiyle çok uyumlu bir bağlantı olabilir.'
        : compatibilityScore > 0.6
          ? 'İyi uyum! Ortak noktalar bulunmaktadır.'
          : 'Farklı perspektifler! Birbirinden öğrenebileceğiniz çok şey olabilir.';

    const insights = {
      commonalities: compatibilityScore > 0.6 ? ['Benzer fal türleri', 'Uyumlu şans unsurları'] : [],
      differences: compatibilityScore <= 0.6 ? ['Farklı fal perspektifi', 'Farklı şans numaraları'] : [],
      potentialGrowth: ['Karşılıklı anlayış', 'Yeni perspektifler kazanma'],
    };

    const recommendations = [
      'Fal bulguşlarını paylaşmayı deneyin',
      'Ortak noktaları keşfetmeyi sürdürün',
      'Farklılıkları anlamaya çalışın',
    ];

    return { analysis, insights, recommendations };
  }

  async getMatches(userId: string, limit: number = 20, offset: number = 0) {
    return prisma.fortuneMatch.findMany({
      where: {
        OR: [{ userId1: userId }, { userId2: userId }],
      },
      take: limit,
      skip: offset,
      orderBy: { compatibilityScore: 'desc' },
      include: { user1: true, user2: true },
    });
  }

  async getMatchDetail(matchId: string) {
    return prisma.fortuneMatch.findUnique({
      where: { id: matchId },
      include: {
        user1: true,
        user2: true,
      },
    });
  }

  async shareMatch(matchId: string) {
    return prisma.fortuneMatch.update({
      where: { id: matchId },
      data: { shared: true, sharedAt: new Date() },
    });
  }

  async recordView(userId: string, matchId: string) {
    return prisma.fortuneMatchView.create({
      data: {
        userId,
        matchId,
      },
    });
  }

  async getMatchHistory(matchId: string) {
    return prisma.fortuneMatchView.findMany({
      where: { matchId },
      orderBy: { viewedAt: 'desc' },
    });
  }
}

const service = new FortuneMatchingService();

router.post('/matches', requireAuth, async (req, res) => {
  try {
    const userId1 = req.userId!;
    const { userId2, fortuneId1, fortuneId2 } = req.body as {
      userId2: string;
      fortuneId1?: string;
      fortuneId2?: string;
    };

    if (!userId2) {
      return res.status(400).json({
        ok: false,
        error: 'userId2 is required',
      } as FortuneMatchResponse);
    }

    const [user1, user2, fortune1, fortune2] = await Promise.all([
      prisma.user.findUnique({ where: { id: userId1 } }),
      prisma.user.findUnique({ where: { id: userId2 } }),
      fortuneId1 ? prisma.userFortune.findUnique({ where: { id: fortuneId1 } }) : null,
      fortuneId2 ? prisma.userFortune.findUnique({ where: { id: fortuneId2 } }) : null,
    ]);

    if (!user1 || !user2) {
      return res.status(404).json({
        ok: false,
        error: 'One or both users not found',
      } as FortuneMatchResponse);
    }

    const compatibilityScore = await service.calculateCompatibility(
      user1,
      user2,
      fortune1,
      fortune2,
    );

    const { analysis, insights, recommendations } = await service.generateInsights(
      userId1,
      userId2,
      compatibilityScore,
    );

    const match = await prisma.fortuneMatch.upsert({
      where: {
        userId1_userId2: { userId1, userId2 },
      },
      update: {
        compatibilityScore,
        analysis,
        insights,
        recommendations,
      },
      create: {
        userId1,
        userId2,
        fortuneId1,
        fortuneId2,
        compatibilityScore,
        matchType: 'general',
        analysis,
        insights,
        recommendations,
      },
      include: { user1: true, user2: true },
    });

    res.json({
      ok: true,
      data: match,
    } as FortuneMatchResponse);
  } catch (error: any) {
    console.error('Fortune matching error:', error);
    res.status(500).json({
      ok: false,
      error: error.message,
    } as FortuneMatchResponse);
  }
});

router.get('/matches', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const limit = parseInt(req.query.limit as string) || 20;
    const offset = parseInt(req.query.offset as string) || 0;

    const matches = await service.getMatches(userId, limit, offset);

    res.json({
      ok: true,
      data: { matches },
    } as FortuneMatchResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as FortuneMatchResponse);
  }
});

router.get('/matches/:id', requireAuth, async (req, res) => {
  try {
    const match = await service.getMatchDetail(req.params.id);

    if (!match) {
      return res.status(404).json({
        ok: false,
        error: 'Match not found',
      } as FortuneMatchResponse);
    }

    res.json({
      ok: true,
      data: match,
    } as FortuneMatchResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as FortuneMatchResponse);
  }
});

router.put('/matches/:id/share', requireAuth, async (req, res) => {
  try {
    const match = await service.shareMatch(req.params.id);

    res.json({
      ok: true,
      data: match,
    } as FortuneMatchResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as FortuneMatchResponse);
  }
});

router.post('/matches/:id/view', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const view = await service.recordView(userId, req.params.id);

    res.json({
      ok: true,
      data: view,
    } as FortuneMatchResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as FortuneMatchResponse);
  }
});

router.get('/matches/:id/history', requireAuth, async (req, res) => {
  try {
    const history = await service.getMatchHistory(req.params.id);

    res.json({
      ok: true,
      data: { history },
    } as FortuneMatchResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as FortuneMatchResponse);
  }
});

export default router;
