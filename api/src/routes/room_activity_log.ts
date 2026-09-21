import { Router, Request, Response } from "express";
import { PrismaClient } from "@prisma/client";
import { requireAuth } from "../middleware/requireAuth";

const prisma = new PrismaClient();
const router = Router();

class RoomActivityLogService {
  async logActivity(
    roomId: string,
    userId: string | null,
    action: string,
    details?: string,
    metadata?: Record<string, any>
  ) {
    return prisma.roomActivityLog.create({
      data: {
        roomId,
        userId,
        action,
        details,
        metadata,
      },
    });
  }

  async getRoomActivityLogs(roomId: string, limit = 50) {
    return prisma.roomActivityLog.findMany({
      where: { roomId },
      take: limit,
      orderBy: { createdAt: "desc" },
      include: {
        user: {
          select: {
            id: true,
            username: true,
            displayName: true,
            avatarUrl: true,
          },
        },
      },
    });
  }

  async getUserActivityLogs(userId: string, limit = 50) {
    return prisma.roomActivityLog.findMany({
      where: { userId },
      take: limit,
      orderBy: { createdAt: "desc" },
    });
  }

  async getActivityByAction(roomId: string, action: string, limit = 50) {
    return prisma.roomActivityLog.findMany({
      where: { roomId, action },
      take: limit,
      orderBy: { createdAt: "desc" },
    });
  }

  async getRoomActivityStats(roomId: string) {
    const logs = await prisma.roomActivityLog.findMany({
      where: { roomId },
    });

    const actionCounts = logs.reduce(
      (acc, log) => {
        acc[log.action] = (acc[log.action] || 0) + 1;
        return acc;
      },
      {} as Record<string, number>
    );

    return {
      totalActions: logs.length,
      actionCounts,
      latestActivity: logs[0],
    };
  }

  async cleanupOldLogs(roomId: string, daysOld = 30) {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - daysOld);

    return prisma.roomActivityLog.deleteMany({
      where: {
        roomId,
        createdAt: {
          lt: cutoffDate,
        },
      },
    });
  }
}

const service = new RoomActivityLogService();

router.get("/rooms/:roomId/activity", async (req: Request, res: Response) => {
  try {
    const { roomId } = req.params;
    const limit = parseInt(req.query.limit as string) || 50;

    const logs = await service.getRoomActivityLogs(roomId, limit);

    return res.status(200).json({
      success: true,
      data: logs,
    });
  } catch (error) {
    console.error("getRoomActivityLogs error:", error);
    return res.status(500).json({
      success: false,
      message: "Aktivite günlükleri alınamadı",
    });
  }
});

router.post("/rooms/:roomId/activity", requireAuth, async (req: Request, res: Response) => {
  try {
    const { roomId } = req.params;
    const userId = (req as any).user?.id;
    const { action, details, metadata } = req.body;

    const log = await service.logActivity(roomId, userId, action, details, metadata);

    return res.status(201).json({
      success: true,
      data: log,
    });
  } catch (error) {
    console.error("logActivity error:", error);
    return res.status(500).json({
      success: false,
      message: "Aktivite kaydedilemedi",
    });
  }
});

router.get("/rooms/:roomId/activity/stats", async (req: Request, res: Response) => {
  try {
    const { roomId } = req.params;

    const stats = await service.getRoomActivityStats(roomId);

    return res.status(200).json({
      success: true,
      data: stats,
    });
  } catch (error) {
    console.error("getRoomActivityStats error:", error);
    return res.status(500).json({
      success: false,
      message: "Aktivite istatistikleri alınamadı",
    });
  }
});

router.get("/rooms/:roomId/activity/:action", async (req: Request, res: Response) => {
  try {
    const { roomId, action } = req.params;
    const limit = parseInt(req.query.limit as string) || 50;

    const logs = await service.getActivityByAction(roomId, action, limit);

    return res.status(200).json({
      success: true,
      data: logs,
    });
  } catch (error) {
    console.error("getActivityByAction error:", error);
    return res.status(500).json({
      success: false,
      message: "Aktivite günlükleri alınamadı",
    });
  }
});

router.post("/rooms/:roomId/activity/cleanup", requireAuth, async (req: Request, res: Response) => {
  try {
    const { roomId } = req.params;
    const { daysOld } = req.body;

    const result = await service.cleanupOldLogs(roomId, daysOld || 30);

    return res.status(200).json({
      success: true,
      message: "Eski günlükler temizlendi",
      deletedCount: result.count,
    });
  } catch (error) {
    console.error("cleanupOldLogs error:", error);
    return res.status(500).json({
      success: false,
      message: "Günlükler temizlenemedi",
    });
  }
});

export const roomActivityLogRouter = router;
