import { Router, Request, Response } from "express";
import { prisma } from "../lib/prisma";
import { requireAuth } from "../middleware/requireAuth";
import { fail, success } from "../lib/response";

const router = Router();

class StreamModerationService {
  async recordModerationAction(
    streamId: string,
    action: string,
    targetUserId: string,
    moderatorId: string | null,
    data: { reason?: string; duration?: number; metadata?: any }
  ) {
    return prisma.streamModerationLog.create({
      data: {
        streamId,
        action,
        targetUserId,
        moderatorId,
        reason: data.reason,
        duration: data.duration,
        metadata: data.metadata,
      },
      include: {
        targetUser: { select: { id: true, displayName: true, avatarUrl: true } },
        moderator: { select: { id: true, displayName: true } },
      },
    });
  }

  async getModerationLogs(streamId: string, limit = 50, offset = 0) {
    const [logs, total] = await Promise.all([
      prisma.streamModerationLog.findMany({
        where: { streamId },
        include: {
          targetUser: { select: { id: true, displayName: true, avatarUrl: true } },
          moderator: { select: { id: true, displayName: true } },
        },
        orderBy: { createdAt: "desc" },
        take: limit,
        skip: offset,
      }),
      prisma.streamModerationLog.count({ where: { streamId } }),
    ]);

    return { logs, total, hasMore: offset + limit < total };
  }

  async getModerationStats(streamId: string) {
    const stats = await prisma.streamModerationLog.groupBy({
      by: ["action"],
      where: { streamId },
      _count: true,
    });

    const result = {} as Record<string, number>;
    stats.forEach((stat) => {
      result[stat.action] = stat._count;
    });

    return result;
  }

  async getUserModerationHistory(streamId: string, userId: string) {
    return prisma.streamModerationLog.findMany({
      where: { streamId, targetUserId: userId },
      include: {
        moderator: { select: { id: true, displayName: true } },
      },
      orderBy: { createdAt: "desc" },
    });
  }
}

const service = new StreamModerationService();

router.post(
  "/video-streams/:streamId/moderation/action",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { streamId } = req.params;
      const { action, targetUserId, reason, duration, metadata } = req.body;
      const userId = (req as any).userId;

      if (!action || !targetUserId) {
        return fail(res, 400, "VALIDATION_ERROR", "action ve targetUserId gerekli");
      }

      const log = await service.recordModerationAction(
        streamId,
        action,
        targetUserId,
        userId,
        { reason, duration, metadata }
      );

      return success(res, 201, log, "Moderasyon işlemi kaydedildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Moderasyon işlemi kaydedilemedi");
    }
  }
);

router.get(
  "/video-streams/:streamId/moderation/logs",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { streamId } = req.params;
      const limit = Math.min(parseInt(req.query.limit as string) || 50, 100);
      const offset = parseInt(req.query.offset as string) || 0;

      const result = await service.getModerationLogs(streamId, limit, offset);

      return success(res, 200, result, "Moderasyon logları getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Moderasyon logları getirilemedi");
    }
  }
);

router.get(
  "/video-streams/:streamId/moderation/stats",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { streamId } = req.params;
      const stats = await service.getModerationStats(streamId);

      return success(res, 200, stats, "Moderasyon istatistikleri getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Moderasyon istatistikleri getirilemedi");
    }
  }
);

router.get(
  "/video-streams/:streamId/moderation/user/:userId/history",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { streamId, userId } = req.params;

      const history = await service.getUserModerationHistory(streamId, userId);

      return success(res, 200, history, "Kullanıcı moderasyon geçmişi getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Kullanıcı moderasyon geçmişi getirilemedi");
    }
  }
);

export { router as streamModerationRouter };
