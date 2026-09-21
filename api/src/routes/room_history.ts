import { Router, Request, Response } from "express";
import { PrismaClient } from "@prisma/client";
import { requireAuth } from "../middleware/requireAuth";

const prisma = new PrismaClient();
const router = Router();

class RoomHistoryService {
  async recordVisit(roomId: string, userId: string, durationSeconds = 0) {
    return prisma.roomVisit.create({
      data: {
        roomId,
        userId,
        durationSeconds,
        visitedAt: new Date(),
      },
    });
  }

  async getUserRoomHistory(userId: string, limit = 50) {
    return prisma.roomVisit.findMany({
      where: { userId },
      take: limit,
      orderBy: { visitedAt: "desc" },
    });
  }

  async getUserFavoriteRooms(userId: string, limit = 50) {
    return prisma.roomFavorite.findMany({
      where: { userId },
      take: limit,
      orderBy: { createdAt: "desc" },
    });
  }

  async addRoomToFavorites(roomId: string, userId: string, rating?: number, notes?: string) {
    return prisma.roomFavorite.upsert({
      where: {
        roomId_userId: {
          roomId,
          userId,
        },
      },
      create: {
        roomId,
        userId,
        rating,
        notes,
      },
      update: {
        rating,
        notes,
        updatedAt: new Date(),
      },
    });
  }

  async removeRoomFromFavorites(roomId: string, userId: string) {
    return prisma.roomFavorite.delete({
      where: {
        roomId_userId: {
          roomId,
          userId,
        },
      },
    });
  }

  async isRoomFavorited(roomId: string, userId: string) {
    const favorite = await prisma.roomFavorite.findUnique({
      where: {
        roomId_userId: {
          roomId,
          userId,
        },
      },
    });

    return !!favorite;
  }

  async getUserMostVisitedRooms(userId: string, limit = 10) {
    const visits = await prisma.roomVisit.findMany({
      where: { userId },
      orderBy: { visitedAt: "desc" },
    });

    const roomVisitCounts = new Map<string, { count: number; lastVisited: Date }>();

    visits.forEach((visit) => {
      const existing = roomVisitCounts.get(visit.roomId);
      roomVisitCounts.set(visit.roomId, {
        count: (existing?.count || 0) + 1,
        lastVisited: visit.visitedAt,
      });
    });

    return Array.from(roomVisitCounts.entries())
      .sort((a, b) => b[1].count - a[1].count)
      .slice(0, limit)
      .map(([roomId, data]) => ({
        roomId,
        ...data,
      }));
  }

  async getUserAverageVisitDuration(userId: string) {
    const visits = await prisma.roomVisit.findMany({
      where: { userId },
      select: { durationSeconds: true },
    });

    if (visits.length === 0) return 0;

    const totalSeconds = visits.reduce((sum, v) => sum + v.durationSeconds, 0);
    return Math.round(totalSeconds / visits.length);
  }

  async getRoomVisitorStats(roomId: string) {
    const visits = await prisma.roomVisit.findMany({
      where: { roomId },
    });

    const uniqueVisitors = new Set(visits.map((v) => v.userId)).size;
    const totalVisits = visits.length;
    const totalDuration = visits.reduce((sum, v) => sum + v.durationSeconds, 0);
    const averageDuration = totalVisits > 0 ? totalDuration / totalVisits : 0;

    return {
      uniqueVisitors,
      totalVisits,
      totalDuration,
      averageDuration: Math.round(averageDuration),
    };
  }

  async cleanupOldVisits(daysOld = 90) {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - daysOld);

    return prisma.roomVisit.deleteMany({
      where: {
        visitedAt: {
          lt: cutoffDate,
        },
      },
    });
  }
}

const service = new RoomHistoryService();

router.get("/user/room-history", requireAuth, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.id;
    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "Yetkilendirme gerekli",
      });
    }

    const limit = parseInt(req.query.limit as string) || 50;
    const history = await service.getUserRoomHistory(userId, limit);

    return res.status(200).json({
      success: true,
      data: history,
    });
  } catch (error) {
    console.error("getUserRoomHistory error:", error);
    return res.status(500).json({
      success: false,
      message: "Oda geçmişi alınamadı",
    });
  }
});

router.post("/rooms/:roomId/visit", requireAuth, async (req: Request, res: Response) => {
  try {
    const { roomId } = req.params;
    const userId = (req as any).user?.id;
    const { durationSeconds } = req.body;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "Yetkilendirme gerekli",
      });
    }

    const visit = await service.recordVisit(roomId, userId, durationSeconds || 0);

    return res.status(201).json({
      success: true,
      data: visit,
    });
  } catch (error) {
    console.error("recordVisit error:", error);
    return res.status(500).json({
      success: false,
      message: "Ziyaret kaydedilemedi",
    });
  }
});

router.get("/user/favorites", requireAuth, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.id;
    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "Yetkilendirme gerekli",
      });
    }

    const limit = parseInt(req.query.limit as string) || 50;
    const favorites = await service.getUserFavoriteRooms(userId, limit);

    return res.status(200).json({
      success: true,
      data: favorites,
    });
  } catch (error) {
    console.error("getUserFavoriteRooms error:", error);
    return res.status(500).json({
      success: false,
      message: "Favoriler alınamadı",
    });
  }
});

router.post("/rooms/:roomId/favorite", requireAuth, async (req: Request, res: Response) => {
  try {
    const { roomId } = req.params;
    const userId = (req as any).user?.id;
    const { rating, notes } = req.body;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "Yetkilendirme gerekli",
      });
    }

    const favorite = await service.addRoomToFavorites(roomId, userId, rating, notes);

    return res.status(201).json({
      success: true,
      data: favorite,
    });
  } catch (error) {
    console.error("addRoomToFavorites error:", error);
    return res.status(500).json({
      success: false,
      message: "Favori eklenemedi",
    });
  }
});

router.delete("/rooms/:roomId/favorite", requireAuth, async (req: Request, res: Response) => {
  try {
    const { roomId } = req.params;
    const userId = (req as any).user?.id;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "Yetkilendirme gerekli",
      });
    }

    await service.removeRoomFromFavorites(roomId, userId);

    return res.status(200).json({
      success: true,
      message: "Favori kaldırıldı",
    });
  } catch (error) {
    console.error("removeRoomFromFavorites error:", error);
    return res.status(500).json({
      success: false,
      message: "Favori kaldırılamadı",
    });
  }
});

router.get("/rooms/:roomId/visitor-stats", async (req: Request, res: Response) => {
  try {
    const { roomId } = req.params;

    const stats = await service.getRoomVisitorStats(roomId);

    return res.status(200).json({
      success: true,
      data: stats,
    });
  } catch (error) {
    console.error("getRoomVisitorStats error:", error);
    return res.status(500).json({
      success: false,
      message: "Ziyaretçi istatistikleri alınamadı",
    });
  }
});

router.get("/user/most-visited-rooms", requireAuth, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.id;
    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "Yetkilendirme gerekli",
      });
    }

    const limit = parseInt(req.query.limit as string) || 10;
    const rooms = await service.getUserMostVisitedRooms(userId, limit);

    return res.status(200).json({
      success: true,
      data: rooms,
    });
  } catch (error) {
    console.error("getUserMostVisitedRooms error:", error);
    return res.status(500).json({
      success: false,
      message: "En çok ziyaret edilen odalar alınamadı",
    });
  }
});

export const roomHistoryRouter = router;
