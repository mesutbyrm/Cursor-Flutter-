import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import requireAuth from '../middleware/requireAuth';

const router = Router();
const prisma = new PrismaClient();

interface AnalyticsResponse {
  ok: boolean;
  data?: any;
  error?: string;
}

class AnalyticsService {
  async getUserMetrics(userId: string) {
    return prisma.userAnalytics.findUnique({
      where: { userId },
    });
  }

  async updateUserMetrics(userId: string) {
    const [readingCount, voiceReadingCount, currentStreak] = await Promise.all([
      prisma.userFortune.count({
        where: { userId },
      }),
      prisma.voiceFortune.count({
        where: { userId },
      }),
      prisma.userStreak
        .findUnique({
          where: { userId },
        })
        .then((s) => s?.currentStreak || 0),
    ]);

    const matchCount = await prisma.fortuneMatch.count({
      where: {
        OR: [{ userId1: userId }, { userId2: userId }],
      },
    });

    const metrics = await prisma.userAnalytics.upsert({
      where: { userId },
      update: {
        totalReadings: readingCount,
        totalVoiceReadings: voiceReadingCount,
        totalMatches: matchCount,
        currentStreak,
        engagementScore: Math.min(100, readingCount * 2 + voiceReadingCount * 5),
        lastActiveAt: new Date(),
      },
      create: {
        userId,
        totalReadings: readingCount,
        totalVoiceReadings: voiceReadingCount,
        totalMatches: matchCount,
        currentStreak,
        engagementScore: Math.min(100, readingCount * 2 + voiceReadingCount * 5),
      },
    });

    return metrics;
  }

  async getDailySnapshot(userId: string, date: Date) {
    const startOfDay = new Date(date);
    startOfDay.setHours(0, 0, 0, 0);

    const endOfDay = new Date(date);
    endOfDay.setHours(23, 59, 59, 999);

    const [readingCount, voiceReadingCount, matchCount, shareCount] =
      await Promise.all([
        prisma.userFortune.count({
          where: {
            userId,
            createdAt: { gte: startOfDay, lte: endOfDay },
          },
        }),
        prisma.voiceFortune.count({
          where: {
            userId,
            createdAt: { gte: startOfDay, lte: endOfDay },
          },
        }),
        prisma.fortuneMatch.count({
          where: {
            OR: [
              { userId1: userId, createdAt: { gte: startOfDay, lte: endOfDay } },
              { userId2: userId, createdAt: { gte: startOfDay, lte: endOfDay } },
            ],
          },
        }),
        prisma.socialFortunePost.count({
          where: {
            userId,
            createdAt: { gte: startOfDay, lte: endOfDay },
          },
        }),
      ]);

    return prisma.analyticsSnapshot.upsert({
      where: {
        userId_date_period: {
          userId,
          date: date,
          period: 'daily',
        },
      },
      update: {
        readingCount,
        voiceReadingCount,
        matchCount,
        shareCount,
      },
      create: {
        userId,
        date,
        period: 'daily',
        readingCount,
        voiceReadingCount,
        matchCount,
        shareCount,
      },
    });
  }

  async getAnalyticsPeriod(
    userId: string,
    startDate: Date,
    endDate: Date,
    period: string = 'daily',
  ) {
    return prisma.analyticsSnapshot.findMany({
      where: {
        userId,
        date: { gte: startDate, lte: endDate },
        period,
      },
      orderBy: { date: 'asc' },
    });
  }

  async getEngagementTrend(userId: string, days: number = 30) {
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    const snapshots = await this.getAnalyticsPeriod(
      userId,
      startDate,
      new Date(),
      'daily',
    );

    const trend = snapshots.map((s) => ({
      date: s.date,
      readings: s.readingCount,
      voicereadings: s.voiceReadingCount,
      engagementScore: (s.readingCount * 2 + s.voiceReadingCount * 5) * 0.8,
    }));

    return trend;
  }

  async generateReport(userId: string) {
    const metrics = await this.getUserMetrics(userId);
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const monthlySnapshots = await this.getAnalyticsPeriod(
      userId,
      thirtyDaysAgo,
      new Date(),
      'daily',
    );

    const totalReadingsMonth = monthlySnapshots.reduce(
      (acc, s) => acc + s.readingCount,
      0,
    );
    const totalVoiceMonth = monthlySnapshots.reduce(
      (acc, s) => acc + s.voiceReadingCount,
      0,
    );
    const avgDailyReadings = Math.round(totalReadingsMonth / 30);

    return {
      metrics,
      monthlyStats: {
        totalReadings: totalReadingsMonth,
        totalVoiceReadings: totalVoiceMonth,
        averageDailyReadings: avgDailyReadings,
        activeStreak: metrics?.currentStreak || 0,
        totalMatches: metrics?.totalMatches || 0,
      },
      recommendations: [
        avgDailyReadings < 1
          ? 'Günlük fal okuma alışkanlığınız geliştirilebilir'
          : 'Harika günlük fal alışkanlığını devam ettirin!',
        metrics && metrics.totalMatches > 0
          ? 'Eşleştirme sonuçlarınızı paylaşmayı deneyin'
          : 'Başkalarıyla fal eşleştirmelerini keşfedin',
      ],
    };
  }
}

const service = new AnalyticsService();

router.get('/metrics', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;

    const metrics = await service.updateUserMetrics(userId);

    res.json({
      ok: true,
      data: metrics,
    } as AnalyticsResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as AnalyticsResponse);
  }
});

router.get('/snapshot', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const date = req.query.date
      ? new Date(req.query.date as string)
      : new Date();

    const snapshot = await service.getDailySnapshot(userId, date);

    res.json({
      ok: true,
      data: snapshot,
    } as AnalyticsResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as AnalyticsResponse);
  }
});

router.get('/trend', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const days = parseInt(req.query.days as string) || 30;

    const trend = await service.getEngagementTrend(userId, days);

    res.json({
      ok: true,
      data: { trend },
    } as AnalyticsResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as AnalyticsResponse);
  }
});

router.get('/period', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const startDate = new Date(req.query.startDate as string);
    const endDate = new Date(req.query.endDate as string);
    const period = (req.query.period as string) || 'daily';

    if (isNaN(startDate.getTime()) || isNaN(endDate.getTime())) {
      return res.status(400).json({
        ok: false,
        error: 'Invalid date format',
      } as AnalyticsResponse);
    }

    const data = await service.getAnalyticsPeriod(
      userId,
      startDate,
      endDate,
      period,
    );

    res.json({
      ok: true,
      data: { snapshots: data },
    } as AnalyticsResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as AnalyticsResponse);
  }
});

router.get('/report', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;

    const report = await service.generateReport(userId);

    res.json({
      ok: true,
      data: report,
    } as AnalyticsResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as AnalyticsResponse);
  }
});

export default router;
