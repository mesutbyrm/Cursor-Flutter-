import { Router, Request, Response } from "express";
import { PrismaClient } from "@prisma/client";
import { requireAuth } from "../middleware/requireAuth";

const prisma = new PrismaClient();
const router = Router();

class RoomAchievementService {
  async createAchievement(
    roomId: string,
    data: {
      name: string;
      description?: string;
      icon?: string;
      triggerType: string;
      triggerValue: number;
    }
  ) {
    return prisma.roomAchievement.create({
      data: {
        roomId,
        ...data,
      },
    });
  }

  async getRoomAchievements(roomId: string) {
    return prisma.roomAchievement.findMany({
      where: { roomId, isActive: true },
    });
  }

  async awardBadgeToUser(
    userId: string,
    badgeType: string,
    badgeName: string,
    badgeIcon?: string,
    badgeDescription?: string
  ) {
    return prisma.userBadge.upsert({
      where: {
        userId_badgeType: {
          userId,
          badgeType,
        },
      },
      create: {
        userId,
        badgeType,
        badgeName,
        badgeIcon,
        badgeDescription,
      },
      update: {
        badgeName,
        badgeIcon,
        badgeDescription,
        earnedAt: new Date(),
      },
    });
  }

  async getUserBadges(userId: string) {
    return prisma.userBadge.findMany({
      where: { userId },
      orderBy: { earnedAt: "desc" },
    });
  }

  async getUserBadgesByType(userId: string, badgeType: string) {
    return prisma.userBadge.findMany({
      where: { userId, badgeType },
    });
  }

  async hasBadge(userId: string, badgeType: string) {
    const badge = await prisma.userBadge.findUnique({
      where: {
        userId_badgeType: {
          userId,
          badgeType,
        },
      },
    });

    return !!badge;
  }

  async removeBadge(userId: string, badgeType: string) {
    return prisma.userBadge.delete({
      where: {
        userId_badgeType: {
          userId,
          badgeType,
        },
      },
    });
  }

  async checkAndAwardAchievements(roomId: string, userId: string, triggerType: string, currentValue: number) {
    const achievements = await prisma.roomAchievement.findMany({
      where: {
        roomId,
        triggerType,
        isActive: true,
      },
    });

    const awardedBadges = [];

    for (const achievement of achievements) {
      if (currentValue >= achievement.triggerValue) {
        const hasBadge = await this.hasBadge(userId, achievement.id);
        if (!hasBadge) {
          const badge = await this.awardBadgeToUser(userId, achievement.id, achievement.name, achievement.icon, achievement.description);
          awardedBadges.push(badge);
        }
      }
    }

    return awardedBadges;
  }

  async getRoomAchievementStats(roomId: string) {
    const achievements = await prisma.roomAchievement.findMany({
      where: { roomId },
    });

    const stats = [];

    for (const achievement of achievements) {
      const earnedCount = await prisma.userBadge.count({
        where: { badgeType: achievement.id },
      });

      stats.push({
        achievement,
        earnedCount,
      });
    }

    return stats;
  }
}

const service = new RoomAchievementService();

router.get("/rooms/:roomId/achievements", async (req: Request, res: Response) => {
  try {
    const { roomId } = req.params;

    const achievements = await service.getRoomAchievements(roomId);

    return res.status(200).json({
      success: true,
      data: achievements,
    });
  } catch (error) {
    console.error("getRoomAchievements error:", error);
    return res.status(500).json({
      success: false,
      message: "Başarılar alınamadı",
    });
  }
});

router.post("/rooms/:roomId/achievements", requireAuth, async (req: Request, res: Response) => {
  try {
    const { roomId } = req.params;
    const { name, description, icon, triggerType, triggerValue } = req.body;

    const achievement = await service.createAchievement(roomId, {
      name,
      description,
      icon,
      triggerType,
      triggerValue,
    });

    return res.status(201).json({
      success: true,
      data: achievement,
    });
  } catch (error) {
    console.error("createAchievement error:", error);
    return res.status(500).json({
      success: false,
      message: "Başarı oluşturulamadı",
    });
  }
});

router.get("/user/badges", requireAuth, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.id;
    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "Yetkilendirme gerekli",
      });
    }

    const badges = await service.getUserBadges(userId);

    return res.status(200).json({
      success: true,
      data: badges,
    });
  } catch (error) {
    console.error("getUserBadges error:", error);
    return res.status(500).json({
      success: false,
      message: "Rozetler alınamadı",
    });
  }
});

router.post("/user/award-badge", requireAuth, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.id;
    const { badgeType, badgeName, badgeIcon, badgeDescription } = req.body;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "Yetkilendirme gerekli",
      });
    }

    const badge = await service.awardBadgeToUser(userId, badgeType, badgeName, badgeIcon, badgeDescription);

    return res.status(201).json({
      success: true,
      data: badge,
    });
  } catch (error) {
    console.error("awardBadgeToUser error:", error);
    return res.status(500).json({
      success: false,
      message: "Rozet verilemedi",
    });
  }
});

router.post("/rooms/:roomId/check-achievements", requireAuth, async (req: Request, res: Response) => {
  try {
    const { roomId } = req.params;
    const userId = (req as any).user?.id;
    const { triggerType, currentValue } = req.body;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "Yetkilendirme gerekli",
      });
    }

    const awardedBadges = await service.checkAndAwardAchievements(roomId, userId, triggerType, currentValue);

    return res.status(200).json({
      success: true,
      data: {
        awardedBadges,
        count: awardedBadges.length,
      },
    });
  } catch (error) {
    console.error("checkAndAwardAchievements error:", error);
    return res.status(500).json({
      success: false,
      message: "Başarılar kontrol edilemedi",
    });
  }
});

router.get("/rooms/:roomId/achievements/stats", async (req: Request, res: Response) => {
  try {
    const { roomId } = req.params;

    const stats = await service.getRoomAchievementStats(roomId);

    return res.status(200).json({
      success: true,
      data: stats,
    });
  } catch (error) {
    console.error("getRoomAchievementStats error:", error);
    return res.status(500).json({
      success: false,
      message: "Başarı istatistikleri alınamadı",
    });
  }
});

export const roomAchievementsRouter = router;
