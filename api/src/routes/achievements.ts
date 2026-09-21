import { Router, Request, Response } from "express";
import { PrismaClient } from "@prisma/client";
import { requireAuth } from "../middleware/requireAuth";
import { fail, ok } from "../lib/response";

const prisma = new PrismaClient();
const router = Router();

// GET /api/achievements/streaks
router.get("/streaks", requireAuth, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.id;
    if (!userId) return res.status(401).json(fail("Kimlik doğrulaması başarısız"));

    const streak = await prisma.userStreak.findUnique({
      where: { userId },
    });

    if (!streak) {
      // Create default streak record
      const newStreak = await prisma.userStreak.create({
        data: { userId },
      });

      return res.json(ok({
        currentStreak: 0,
        bestStreak: 0,
        bestStreakStart: null,
        bestStreakEnd: null,
        totalReadingsInStreak: 0,
        lastReadingDate: null,
        streakBrokenDate: null,
        milestones: [
          { streakDays: 7, achievedAt: null, locked: true },
          { streakDays: 30, achievedAt: null, locked: true },
          { streakDays: 100, achievedAt: null, locked: true },
        ],
      }));
    }

    res.json(ok({
      currentStreak: streak.currentStreak,
      bestStreak: streak.bestStreak,
      bestStreakStart: streak.bestStreakStart,
      bestStreakEnd: streak.bestStreakEnd,
      totalReadingsInStreak: streak.totalReadingsInStreak,
      lastReadingDate: streak.lastReadingDate,
      streakBrokenDate: streak.streakBrokenDate,
      milestones: [
        {
          streakDays: 7,
          achievedAt: streak.currentStreak >= 7 ? new Date() : null,
          locked: streak.currentStreak < 7,
        },
        {
          streakDays: 30,
          achievedAt: streak.currentStreak >= 30 ? new Date() : null,
          locked: streak.currentStreak < 30,
        },
        {
          streakDays: 100,
          achievedAt: streak.currentStreak >= 100 ? new Date() : null,
          locked: streak.currentStreak < 100,
        },
      ],
    }));
  } catch (error: any) {
    res.status(500).json(fail("Seri bilgisi alınamadı", error.message));
  }
});

// GET /api/achievements?limit=20&offset=0
router.get("/", requireAuth, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.id;
    if (!userId) return res.status(401).json(fail("Kimlik doğrulaması başarısız"));

    const limit = Math.min(parseInt(req.query.limit as string) || 20, 100);
    const offset = parseInt(req.query.offset as string) || 0;

    const allAchievements = await prisma.achievement.findMany({
      take: limit,
      skip: offset,
      orderBy: { points: "desc" },
    });

    const userAchievements = await prisma.userAchievement.findMany({
      where: { userId },
      include: { achievement: true },
    });

    const achievementMap = new Map(
      userAchievements.map(ua => [ua.achievementId, ua])
    );

    const totalPoints = userAchievements
      .filter(ua => ua.unlockedAt)
      .reduce((sum, ua) => sum + (ua.achievement.points || 0), 0);

    const achievements = allAchievements.map(ach => {
      const userAch = achievementMap.get(ach.id);
      return {
        achievementId: ach.achievementId,
        title: ach.title,
        description: ach.description,
        icon: ach.icon,
        rarity: ach.rarity,
        points: ach.points,
        unlocked: !!userAch?.unlockedAt,
        unlockedAt: userAch?.unlockedAt,
        progress: userAch?.progress || 0,
        maxProgress: userAch?.maxProgress || 1,
      };
    });

    res.json(ok({
      achievements,
      totalPoints,
      totalUnlocked: userAchievements.filter(ua => ua.unlockedAt).length,
    }));
  } catch (error: any) {
    res.status(500).json(fail("Başarılar alınamadı", error.message));
  }
});

// GET /api/achievements/level
router.get("/level", requireAuth, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.id;
    if (!userId) return res.status(401).json(fail("Kimlik doğrulaması başarısız"));

    let level = await prisma.userLevel.findUnique({
      where: { userId },
    });

    if (!level) {
      level = await prisma.userLevel.create({
        data: { userId, level: 1, currentXP: 0, totalXP: 0 },
      });
    }

    const levelNames = [
      "Amatör",
      "Öğrenci",
      "Usta",
      "Kahin",
      "Bilge Kahin",
      "Efsanevi",
    ];

    const nextLevelXP = 5000 * level.level;
    const progress = (level.currentXP / nextLevelXP) * 100;

    res.json(ok({
      level: level.level,
      levelName: levelNames[Math.min(level.level - 1, levelNames.length - 1)],
      currentXP: level.currentXP,
      xpNeeded: nextLevelXP - level.currentXP,
      levelProgress: Math.min(progress, 100),
      totalXP: level.totalXP,
      nextLevelAt: nextLevelXP,
      xpBreakdown: {
        readings: Math.floor(level.totalXP * 0.64),
        shares: Math.floor(level.totalXP * 0.16),
        likes: Math.floor(level.totalXP * 0.1),
        accuracy: Math.floor(level.totalXP * 0.1),
      },
    }));
  } catch (error: any) {
    res.status(500).json(fail("Seviye bilgisi alınamadı", error.message));
  }
});

// POST /api/achievements/{achievementId}/share
router.post("/:achievementId/share", requireAuth, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.id;
    if (!userId) return res.status(401).json(fail("Kimlik doğrulaması başarısız"));

    const { achievementId } = req.params;
    const { platform, text } = req.body;

    const userAch = await prisma.userAchievement.findFirst({
      where: { userId, achievementId },
      include: { achievement: true },
    });

    if (!userAch?.unlockedAt) {
      return res.status(400).json(fail("Bu başarı henüz açılmadı"));
    }

    res.json(ok({
      shareId: `share_${Date.now()}`,
      platform,
      achievement: userAch.achievement.title,
      sharedAt: new Date(),
    }));
  } catch (error: any) {
    res.status(500).json(fail("Başarı paylaşılamadı", error.message));
  }
});

// POST /api/achievements/sync-streaks
router.post("/sync-streaks", requireAuth, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.id;
    if (!userId) return res.status(401).json(fail("Kimlik doğrulaması başarısız"));

    const { lastSyncDate } = req.body;

    let streak = await prisma.userStreak.findUnique({
      where: { userId },
    });

    if (!streak) {
      streak = await prisma.userStreak.create({
        data: { userId },
      });
    }

    // Check if there's a reading today
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const todayReading = await prisma.userFortune.findFirst({
      where: {
        userId,
        createdAt: {
          gte: today,
        },
      },
    });

    if (todayReading && (!streak.lastReadingDate ||
        streak.lastReadingDate.toDateString() !== today.toDateString())) {
      // Increment streak
      const yesterday = new Date(today);
      yesterday.setDate(yesterday.getDate() - 1);

      const yesterdayReading = streak.lastReadingDate?.toDateString() === yesterday.toDateString();

      let newCurrentStreak = streak.currentStreak;
      if (yesterdayReading || streak.currentStreak === 0) {
        newCurrentStreak = streak.currentStreak + 1;
      } else if (!yesterdayReading && streak.currentStreak > 0) {
        newCurrentStreak = 1;
      }

      const newBestStreak = Math.max(newCurrentStreak, streak.bestStreak);

      streak = await prisma.userStreak.update({
        where: { id: streak.id },
        data: {
          currentStreak: newCurrentStreak,
          bestStreak: newBestStreak,
          lastReadingDate: today,
          totalReadingsInStreak: streak.totalReadingsInStreak + 1,
        },
      });
    }

    const unlockedMilestones = [];
    if (streak.currentStreak >= 7) unlockedMilestones.push("7-day-streak");
    if (streak.currentStreak >= 30) unlockedMilestones.push("30-day-streak");
    if (streak.currentStreak >= 100) unlockedMilestones.push("100-day-streak");

    res.json(ok({
      streakUpdated: true,
      currentStreak: streak.currentStreak,
      newMilestonesUnlocked: unlockedMilestones,
      xpGained: unlockedMilestones.length * 50,
      newLevel: false,
    }));
  } catch (error: any) {
    res.status(500).json(fail("Seri senkronize edilemedi", error.message));
  }
});

export const achievementsRouter = router;
