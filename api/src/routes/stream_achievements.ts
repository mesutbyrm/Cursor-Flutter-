import { Router, Request, Response } from "express";
import { prisma } from "../lib/prisma";
import { requireAuth } from "../middleware/requireAuth";
import { fail, success } from "../lib/response";

const router = Router();

class StreamAchievementService {
  private achievements = [
    {
      triggerType: "first_stream",
      triggerValue: 1,
      name: "İlk Yayın",
      icon: "🎬",
      description: "İlk canlı yayınını tamamla",
      rarity: "common",
    },
    {
      triggerType: "total_viewers_100",
      triggerValue: 100,
      name: "Yüz İzleyici",
      icon: "👥",
      description: "100+ izleyici elde et",
      rarity: "common",
    },
    {
      triggerType: "total_viewers_1000",
      triggerValue: 1000,
      name: "Bin İzleyici",
      icon: "🎯",
      description: "1000+ izleyici elde et",
      rarity: "uncommon",
    },
    {
      triggerType: "total_viewers_10000",
      triggerValue: 10000,
      name: "On Bin İzleyici",
      icon: "🚀",
      description: "10000+ izleyici elde et",
      rarity: "rare",
    },
    {
      triggerType: "total_gifts_10",
      triggerValue: 10,
      name: "Hediye Alıcı",
      icon: "🎁",
      description: "10+ hediye al",
      rarity: "common",
    },
    {
      triggerType: "total_gifts_100",
      triggerValue: 100,
      name: "Hediye Severim",
      icon: "🎀",
      description: "100+ hediye al",
      rarity: "uncommon",
    },
    {
      triggerType: "total_revenue_100",
      triggerValue: 100,
      name: "Para Kazandım",
      icon: "💰",
      description: "100+ TL gelir elde et",
      rarity: "uncommon",
    },
    {
      triggerType: "total_revenue_1000",
      triggerValue: 1000,
      name: "Zengin Yayıncı",
      icon: "💎",
      description: "1000+ TL gelir elde et",
      rarity: "rare",
    },
    {
      triggerType: "stream_duration_10",
      triggerValue: 10,
      name: "10 Saat Yayın",
      icon: "⏱️",
      description: "Toplam 10 saat yayın yap",
      rarity: "common",
    },
    {
      triggerType: "stream_duration_100",
      triggerValue: 100,
      name: "100 Saat Yayın",
      icon: "⏲️",
      description: "Toplam 100 saat yayın yap",
      rarity: "rare",
    },
    {
      triggerType: "follower_gain_100",
      triggerValue: 100,
      name: "Yüz Takipçi",
      icon: "⭐",
      description: "100 takipçi kazan",
      rarity: "common",
    },
    {
      triggerType: "follower_gain_1000",
      triggerValue: 1000,
      name: "Bin Takipçi",
      icon: "⭐⭐",
      description: "1000 takipçi kazan",
      rarity: "rare",
    },
  ];

  async checkAndAwardAchievements(hostId: string, streamId: string) {
    const stats = await prisma.hostStreamStats.findUnique({
      where: { hostId },
    });

    if (!stats) return [];

    const awardedAchievements = [];

    for (const achievement of this.achievements) {
      const existing = await prisma.streamAchievement.findUnique({
        where: {
          streamId_hostId_triggerType: {
            streamId,
            hostId,
            triggerType: achievement.triggerType,
          },
        },
      });

      if (existing && existing.unlockedAt) continue;

      let isEarned = false;

      if (
        achievement.triggerType === "first_stream" &&
        stats.totalLiveStreams >= achievement.triggerValue
      ) {
        isEarned = true;
      } else if (
        achievement.triggerType === "total_viewers_100" &&
        stats.peakViewersAllTime >= achievement.triggerValue
      ) {
        isEarned = true;
      } else if (
        achievement.triggerType === "total_viewers_1000" &&
        stats.peakViewersAllTime >= achievement.triggerValue
      ) {
        isEarned = true;
      } else if (
        achievement.triggerType === "total_viewers_10000" &&
        stats.peakViewersAllTime >= achievement.triggerValue
      ) {
        isEarned = true;
      } else if (
        achievement.triggerType === "total_gifts_10" &&
        stats.totalGiftsReceived >= achievement.triggerValue
      ) {
        isEarned = true;
      } else if (
        achievement.triggerType === "total_gifts_100" &&
        stats.totalGiftsReceived >= achievement.triggerValue
      ) {
        isEarned = true;
      } else if (
        achievement.triggerType === "total_revenue_100" &&
        stats.totalRevenue >= achievement.triggerValue
      ) {
        isEarned = true;
      } else if (
        achievement.triggerType === "total_revenue_1000" &&
        stats.totalRevenue >= achievement.triggerValue
      ) {
        isEarned = true;
      } else if (
        achievement.triggerType === "stream_duration_10" &&
        stats.totalViewerMinutes >= achievement.triggerValue * 60
      ) {
        isEarned = true;
      } else if (
        achievement.triggerType === "stream_duration_100" &&
        stats.totalViewerMinutes >= achievement.triggerValue * 60
      ) {
        isEarned = true;
      } else if (
        achievement.triggerType === "follower_gain_100" &&
        stats.followerGainFromStreams >= achievement.triggerValue
      ) {
        isEarned = true;
      } else if (
        achievement.triggerType === "follower_gain_1000" &&
        stats.followerGainFromStreams >= achievement.triggerValue
      ) {
        isEarned = true;
      }

      if (isEarned) {
        const ach = await prisma.streamAchievement.upsert({
          where: {
            streamId_hostId_triggerType: {
              streamId,
              hostId,
              triggerType: achievement.triggerType,
            },
          },
          update: { unlockedAt: new Date(), awardedAt: new Date() },
          create: {
            streamId,
            hostId,
            name: achievement.name,
            icon: achievement.icon,
            description: achievement.description,
            triggerType: achievement.triggerType,
            triggerValue: achievement.triggerValue,
            badge: achievement.icon,
            rarity: achievement.rarity,
            unlockedAt: new Date(),
            awardedAt: new Date(),
          },
        });

        awardedAchievements.push(ach);
      }
    }

    return awardedAchievements;
  }

  async getHostAchievements(hostId: string) {
    return prisma.streamAchievement.findMany({
      where: { hostId, unlockedAt: { not: null } },
      orderBy: { unlockedAt: "desc" },
    });
  }

  async getStreamAchievements(streamId: string) {
    return prisma.streamAchievement.findMany({
      where: { streamId, unlockedAt: { not: null } },
      orderBy: { unlockedAt: "desc" },
    });
  }

  async getAchievementStats(hostId: string) {
    const achievements = await this.getHostAchievements(hostId);
    const rarities = {} as Record<string, number>;

    achievements.forEach((a) => {
      rarities[a.rarity] = (rarities[a.rarity] || 0) + 1;
    });

    return {
      totalAchievements: achievements.length,
      byRarity: rarities,
      achievements,
    };
  }
}

const service = new StreamAchievementService();

router.post(
  "/video-streams/:streamId/achievements/check",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { streamId } = req.params;
      const hostId = (req as any).userId;

      const achievements = await service.checkAndAwardAchievements(
        hostId,
        streamId
      );

      return success(
        res,
        200,
        achievements,
        `${achievements.length} yeni başarı açıldı`
      );
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Başarılar kontrol edilemedi");
    }
  }
);

router.get(
  "/users/:userId/achievements",
  async (req: Request, res: Response) => {
    try {
      const { userId } = req.params;

      const achievements = await service.getHostAchievements(userId);

      return success(res, 200, achievements, "Başarılar getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Başarılar getirilemedi");
    }
  }
);

router.get(
  "/video-streams/:streamId/achievements",
  async (req: Request, res: Response) => {
    try {
      const { streamId } = req.params;

      const achievements = await service.getStreamAchievements(streamId);

      return success(res, 200, achievements, "Yayın başarıları getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Yayın başarıları getirilemedi");
    }
  }
);

router.get(
  "/users/:userId/achievements/stats",
  async (req: Request, res: Response) => {
    try {
      const { userId } = req.params;

      const stats = await service.getAchievementStats(userId);

      return success(res, 200, stats, "Başarı istatistikleri getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Başarı istatistikleri getirilemedi");
    }
  }
);

export { router as streamAchievementsRouter };
