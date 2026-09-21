import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import { requireAuth } from '../middleware/requireAuth';

const router = Router();
const prisma = new PrismaClient();

interface RecommendationResponse {
  ok: boolean;
  data?: any;
  error?: string;
}

interface RoomScore {
  roomId: string;
  score: number;
  reason: string;
}

class VoiceRecommendationService {
  async getRecommendations(userId: string, limit: number = 20): Promise<RoomScore[]> {
    // Öneri algoritması (4 kategori):
    // 1. Tarihçe-bazlı (Recently joined rooms)
    // 2. Trend-bazlı (Popular rooms)
    // 3. Kategori-bazlı (Similar category)
    // 4. Sosyal-bazlı (Friends' rooms)

    const scores: RoomScore[] = [];
    const allRooms = await prisma.voiceRoom.findMany({
      where: { isActive: true },
    });

    for (const room of allRooms) {
      let score = 0;
      let reason = '';

      // 1. Tarihçe: Sık ziyaret edilen odalar
      const recentJoins = await prisma.voiceSession.count({
        where: {
          roomId: room.id,
          userId,
          joinedAt: {
            gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), // Son 30 gün
          },
        },
      });

      if (recentJoins > 0) {
        score += 30;
        reason = `${reason ? reason + ', ' : ''}Sık ziyaret edilen oda`;
      }

      // 2. Trend: Popüler odalar (aktif kullanıcı sayısı)
      const activeUsers = await prisma.voiceSession.count({
        where: {
          roomId: room.id,
          leftAt: null,
        },
      });

      if (activeUsers > 10) {
        score += 25;
        reason = `${reason ? reason + ', ' : ''}Popüler oda`;
      } else if (activeUsers > 5) {
        score += 15;
      }

      // 3. Kalite: Leaderboard skoru
      const leaderboardCount = await prisma.roomLeaderboard.count({
        where: { roomId: room.id },
      });

      if (leaderboardCount > 20) {
        score += 20;
        reason = `${reason ? reason + ', ' : ''}Aktif topluluk`;
      }

      // 4. Sosyal: Arkadaşların bulunduğu odalar
      // (Bu örnek basitçe atlanmış - gerçek uygulamada follow listesi kullanılır)
      const friendsInRoom = 0; // Placeholder
      if (friendsInRoom > 0) {
        score += friendsInRoom * 10;
        reason = `${reason ? reason + ', ' : ''}Arkadaşlar orada`;
      }

      // 5. Taze odalar (Son 7 gün oluşturulmuş)
      const createdRecently = new Date(room.createdAt).getTime() > Date.now() - 7 * 24 * 60 * 60 * 1000;
      if (createdRecently) {
        score += 10;
        reason = `${reason ? reason + ', ' : ''}Yeni oda`;
      }

      // 6. Oda türü tercihine göre
      if (room.roomType === 'VIP') {
        score += 5; // Hafif bonus
      }

      if (score > 0) {
        scores.push({
          roomId: room.id,
          score,
          reason: reason || 'Önerilen oda',
        });
      }
    }

    // Skora göre sırala ve en üstteki N'i döndür
    return scores.sort((a, b) => b.score - a.score).slice(0, limit);
  }

  async getRecommendedRooms(userId: string, limit: number = 20) {
    const recommendations = await this.getRecommendations(userId, limit);

    const rooms = await Promise.all(
      recommendations.map(async (rec) => {
        const room = await prisma.voiceRoom.findUnique({
          where: { id: rec.roomId },
        });

        const activeUsers = await prisma.voiceSession.count({
          where: {
            roomId: rec.roomId,
            leftAt: null,
          },
        });

        return {
          ...room,
          score: rec.score,
          reason: rec.reason,
          activeUsers,
        };
      })
    );

    return rooms.filter((r) => r !== null);
  }

  async getTrendingRooms(limit: number = 10) {
    // Son 24 saat içinde en çok giriş yapılan odalar
    const rooms = await prisma.voiceSession.groupBy({
      by: ['roomId'],
      where: {
        joinedAt: {
          gte: new Date(Date.now() - 24 * 60 * 60 * 1000),
        },
      },
      _count: { roomId: true },
      orderBy: {
        _count: {
          roomId: 'desc',
        },
      },
      take: limit,
    });

    const trendingRooms = await Promise.all(
      rooms.map(async (r) => {
        const room = await prisma.voiceRoom.findUnique({
          where: { id: r.roomId },
        });

        const activeUsers = await prisma.voiceSession.count({
          where: {
            roomId: r.roomId,
            leftAt: null,
          },
        });

        return {
          ...room,
          joins24h: r._count.roomId,
          activeUsers,
        };
      })
    );

    return trendingRooms.filter((r) => r !== null);
  }

  async getPersonalizedRecommendations(userId: string, limit: number = 10) {
    // Kullanıcının geçmişine dayalı daha kişiselleştirilmiş öneriler
    const userStats = await prisma.userVoiceStats.findUnique({
      where: { userId },
    });

    if (!userStats) {
      return this.getTrendingRooms(limit);
    }

    // Kullanıcının en çok ziyaret ettiği odaları bul
    const userHistory = await prisma.voiceSession.groupBy({
      by: ['roomId'],
      where: { userId },
      _count: { roomId: true },
      orderBy: {
        _count: {
          roomId: 'desc',
        },
      },
      take: 5,
    });

    const recommendations = await this.getRecommendedRooms(userId, limit);

    return recommendations;
  }
}

const service = new VoiceRecommendationService();

// GET /api/chat/rooms/recommended?limit=20 — Kişiselleştirilmiş oda önerileri
router.get('/rooms/recommended', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const limit = Math.min(parseInt(req.query.limit as string) || 20, 100);

    const recommendations = await service.getRecommendedRooms(userId, limit);

    res.json({
      ok: true,
      data: {
        recommendations,
        count: recommendations.length,
      },
    } as RecommendationResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as RecommendationResponse);
  }
});

// GET /api/chat/rooms/trending?limit=10 — Trend odalar
router.get('/rooms/trending', async (req, res) => {
  try {
    const limit = Math.min(parseInt(req.query.limit as string) || 10, 50);
    const trending = await service.getTrendingRooms(limit);

    res.json({
      ok: true,
      data: {
        trending,
        count: trending.length,
      },
    } as RecommendationResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as RecommendationResponse);
  }
});

// GET /api/chat/rooms/personalized?limit=10 — Kişiselleştirilmiş öneriler
router.get('/rooms/personalized', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const limit = Math.min(parseInt(req.query.limit as string) || 10, 50);

    const personalized = await service.getPersonalizedRecommendations(userId, limit);

    res.json({
      ok: true,
      data: {
        personalized,
        count: personalized.length,
      },
    } as RecommendationResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as RecommendationResponse);
  }
});

export default router;
