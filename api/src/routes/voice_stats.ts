import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import { requireAuth } from '../middleware/requireAuth';

const router = Router();
const prisma = new PrismaClient();

interface StatsResponse {
  ok: boolean;
  data?: any;
  error?: string;
}

class VoiceStatsService {
  async getUserStats(userId: string) {
    let stats = await prisma.userVoiceStats.findUnique({
      where: { userId },
    });

    // İlk erişimse oluştur
    if (!stats) {
      stats = await prisma.userVoiceStats.create({
        data: { userId },
      });
    }

    return stats;
  }

  async updateUserStats(
    userId: string,
    data: {
      totalMinutesSpeaking?: number;
      totalMinutesListening?: number;
      totalRoomsJoined?: number;
      engagementScore?: number;
      lastActivityAt?: Date;
    }
  ) {
    return prisma.userVoiceStats.upsert({
      where: { userId },
      update: data,
      create: { userId, ...data },
    });
  }

  async getRoomLeaderboard(roomId: string, limit: number = 10, period: 'all' | 'week' | 'month' = 'all') {
    const leaderboard = await prisma.roomLeaderboard.findMany({
      where: { roomId },
      include: { user: { select: { id: true, displayName: true, avatarUrl: true } } },
      orderBy: period === 'week' ? { weeklyRank: 'asc' } : { rank: 'asc' },
      take: limit,
    });

    return leaderboard.map((entry, index) => ({
      ...entry,
      position: index + 1,
    }));
  }

  async updateLeaderboard(roomId: string, userId: string, data: {
    speakingDuration?: number;
    messagesCount?: number;
    giftsReceived?: number;
  }) {
    return prisma.roomLeaderboard.upsert({
      where: { roomId_userId: { roomId, userId } },
      update: data,
      create: { roomId, userId, ...data, rank: 0 },
    });
  }

  async getTopSpeakers(roomId: string, limit: number = 5) {
    return prisma.roomLeaderboard.findMany({
      where: { roomId },
      include: { user: { select: { id: true, displayName: true, avatarUrl: true } } },
      orderBy: { speakingDuration: 'desc' },
      take: limit,
    });
  }

  async getTopGifters(roomId: string, limit: number = 5) {
    return prisma.roomLeaderboard.findMany({
      where: { roomId },
      include: { user: { select: { id: true, displayName: true, avatarUrl: true } } },
      orderBy: { giftsReceived: 'desc' },
      take: limit,
    });
  }

  async calculateEngagementScore(userId: string): Promise<number> {
    const stats = await prisma.userVoiceStats.findUnique({
      where: { userId },
    });

    if (!stats) return 0;

    // Basit formül: konuşma süresi + dinleme süresi + oda sayısı * 10
    const speakingScore = stats.totalMinutesSpeaking * 2;
    const listeningScore = stats.totalMinutesListening * 1;
    const roomsScore = stats.totalRoomsJoined * 10;

    return speakingScore + listeningScore + roomsScore;
  }

  async getRoomAnalytics(roomId: string) {
    const leaderboard = await prisma.roomLeaderboard.findMany({
      where: { roomId },
    });

    const totalSpeakingMinutes = leaderboard.reduce((sum, entry) => sum + entry.speakingDuration, 0);
    const totalMessages = leaderboard.reduce((sum, entry) => sum + entry.messagesCount, 0);
    const totalGifts = leaderboard.reduce((sum, entry) => sum + entry.giftsReceived, 0);
    const avgSpeakingMinutes = leaderboard.length > 0 ? totalSpeakingMinutes / leaderboard.length : 0;

    return {
      totalParticipants: leaderboard.length,
      totalSpeakingMinutes,
      totalMessages,
      totalGifts,
      avgSpeakingMinutes: Math.round(avgSpeakingMinutes),
      topSpeaker: leaderboard.length > 0 ? leaderboard[0].userId : null,
    };
  }
}

const service = new VoiceStatsService();

// GET /api/voice/user-stats — Kullanıcı istatistiklerini al
router.get('/user-stats', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const stats = await service.getUserStats(userId);
    const engagementScore = await service.calculateEngagementScore(userId);

    res.json({
      ok: true,
      data: {
        ...stats,
        engagementScore,
      },
    } as StatsResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as StatsResponse);
  }
});

// GET /api/chat/rooms/:roomId/leaderboard?period=all|week|month&limit=10 — Oda leaderboard'u
router.get('/rooms/:roomId/leaderboard', async (req, res) => {
  try {
    const { roomId } = req.params;
    const period = (req.query.period as string) || 'all';
    const limit = Math.min(parseInt(req.query.limit as string) || 10, 100);

    const leaderboard = await service.getRoomLeaderboard(roomId, limit, period as any);

    res.json({
      ok: true,
      data: { leaderboard },
    } as StatsResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as StatsResponse);
  }
});

// GET /api/chat/rooms/:roomId/top-speakers?limit=5 — En çok konuşan kullanıcılar
router.get('/rooms/:roomId/top-speakers', async (req, res) => {
  try {
    const { roomId } = req.params;
    const limit = Math.min(parseInt(req.query.limit as string) || 5, 50);

    const topSpeakers = await service.getTopSpeakers(roomId, limit);

    res.json({
      ok: true,
      data: { topSpeakers },
    } as StatsResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as StatsResponse);
  }
});

// GET /api/chat/rooms/:roomId/top-gifters?limit=5 — En çok hediye veren kullanıcılar
router.get('/rooms/:roomId/top-gifters', async (req, res) => {
  try {
    const { roomId } = req.params;
    const limit = Math.min(parseInt(req.query.limit as string) || 5, 50);

    const topGifters = await service.getTopGifters(roomId, limit);

    res.json({
      ok: true,
      data: { topGifters },
    } as StatsResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as StatsResponse);
  }
});

// GET /api/chat/rooms/:roomId/analytics — Oda analitiği
router.get('/rooms/:roomId/analytics', async (req, res) => {
  try {
    const { roomId } = req.params;
    const analytics = await service.getRoomAnalytics(roomId);

    res.json({
      ok: true,
      data: analytics,
    } as StatsResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as StatsResponse);
  }
});

// PATCH /api/voice/user-stats — Kullanıcı istatistiklerini güncelle (admin)
router.patch('/user-stats', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const { totalMinutesSpeaking, totalMinutesListening, totalRoomsJoined } = req.body;

    const updated = await service.updateUserStats(userId, {
      totalMinutesSpeaking,
      totalMinutesListening,
      totalRoomsJoined,
      lastActivityAt: new Date(),
    });

    res.json({
      ok: true,
      data: updated,
    } as StatsResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as StatsResponse);
  }
});

export default router;
