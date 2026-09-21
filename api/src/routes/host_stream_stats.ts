import { Router, Request, Response } from "express";
import { prisma } from "../lib/prisma";
import { requireAuth } from "../middleware/requireAuth";
import { fail, success } from "../lib/response";

const router = Router();

class HostStreamStatsService {
  async getOrCreateStats(hostId: string) {
    return prisma.hostStreamStats.upsert({
      where: { hostId },
      update: {},
      create: { hostId },
      include: {
        host: { select: { id: true, displayName: true, avatarUrl: true } },
      },
    });
  }

  async updateStats(
    hostId: string,
    data: {
      totalLiveStreams?: number;
      totalViewerMinutes?: number;
      totalGiftsReceived?: number;
      totalRevenue?: number;
      totalTips?: number;
      averageViewersPerStream?: number;
      averageStreamDuration?: number;
      averageEngagementScore?: number;
      peakViewersAllTime?: number;
      peakViewersMonth?: number;
      followerGainFromStreams?: number;
      unfollowFromStreams?: number;
      streakDays?: number;
    }
  ) {
    const updateData: any = {};

    if (data.totalLiveStreams !== undefined) {
      updateData.totalLiveStreams = data.totalLiveStreams;
    }
    if (data.totalViewerMinutes !== undefined) {
      updateData.totalViewerMinutes = data.totalViewerMinutes;
    }
    if (data.totalGiftsReceived !== undefined) {
      updateData.totalGiftsReceived = data.totalGiftsReceived;
    }
    if (data.totalRevenue !== undefined) {
      updateData.totalRevenue = data.totalRevenue;
    }
    if (data.totalTips !== undefined) {
      updateData.totalTips = data.totalTips;
    }
    if (data.averageViewersPerStream !== undefined) {
      updateData.averageViewersPerStream = data.averageViewersPerStream;
    }
    if (data.averageStreamDuration !== undefined) {
      updateData.averageStreamDuration = data.averageStreamDuration;
    }
    if (data.averageEngagementScore !== undefined) {
      updateData.averageEngagementScore = data.averageEngagementScore;
    }
    if (data.peakViewersAllTime !== undefined) {
      updateData.peakViewersAllTime = Math.max(
        data.peakViewersAllTime,
        (await this.getOrCreateStats(hostId)).peakViewersAllTime
      );
    }
    if (data.peakViewersMonth !== undefined) {
      updateData.peakViewersMonth = data.peakViewersMonth;
    }
    if (data.followerGainFromStreams !== undefined) {
      updateData.followerGainFromStreams = data.followerGainFromStreams;
    }
    if (data.unfollowFromStreams !== undefined) {
      updateData.unfollowFromStreams = data.unfollowFromStreams;
    }
    if (data.streakDays !== undefined) {
      updateData.streakDays = data.streakDays;
    }

    updateData.lastStreamAt = new Date();

    return prisma.hostStreamStats.update({
      where: { hostId },
      data: updateData,
      include: {
        host: { select: { id: true, displayName: true, avatarUrl: true } },
      },
    });
  }

  async incrementStats(hostId: string, data: Record<string, number>) {
    const updates: any = {};

    for (const [key, value] of Object.entries(data)) {
      if (value !== 0) {
        updates[key] = { increment: value };
      }
    }

    if (Object.keys(updates).length === 0) {
      return this.getOrCreateStats(hostId);
    }

    updates.updatedAt = new Date();

    return prisma.hostStreamStats.update({
      where: { hostId },
      data: updates,
      include: {
        host: { select: { id: true, displayName: true, avatarUrl: true } },
      },
    });
  }

  async getStats(hostId: string) {
    return this.getOrCreateStats(hostId);
  }

  async getLeaderboard(
    sortBy: "revenue" | "viewers" | "gifts" | "followers" = "revenue",
    limit = 20
  ) {
    const orderBy: any = {};
    if (sortBy === "revenue") {
      orderBy.totalRevenue = "desc";
    } else if (sortBy === "viewers") {
      orderBy.totalViewerMinutes = "desc";
    } else if (sortBy === "gifts") {
      orderBy.totalGiftsReceived = "desc";
    } else if (sortBy === "followers") {
      orderBy.followerGainFromStreams = "desc";
    }

    const stats = await prisma.hostStreamStats.findMany({
      where: { totalLiveStreams: { gt: 0 } },
      orderBy,
      take: limit,
      include: {
        host: {
          select: {
            id: true,
            displayName: true,
            avatarUrl: true,
            followerCount: true,
          },
        },
      },
    });

    return stats.map((stat, index) => ({
      ...stat,
      rank: index + 1,
    }));
  }

  async getHostRank(
    hostId: string,
    sortBy: "revenue" | "viewers" | "gifts" | "followers" = "revenue"
  ) {
    const leaderboard = await this.getLeaderboard(sortBy, 10000);
    const rank = leaderboard.findIndex((s) => s.hostId === hostId);

    return rank >= 0 ? rank + 1 : null;
  }

  async getMonthlyStats(hostId: string) {
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

    const stats = await prisma.hostStreamStats.findUnique({
      where: { hostId },
    });

    if (!stats || !stats.lastStreamAt || stats.lastStreamAt < thirtyDaysAgo) {
      return {
        activeStreamsMonth: 0,
        peakViewersMonth: stats?.peakViewersMonth || 0,
      };
    }

    return {
      peakViewersMonth: stats.peakViewersMonth,
      activeStreamsMonth: stats.totalLiveStreams,
    };
  }

  async getEngagementAnalysis(hostId: string) {
    const stats = await this.getOrCreateStats(hostId);

    const engagement = {
      averageViewerRetention: stats.averageViewersPerStream > 0
        ? Math.min(100, (stats.totalViewerMinutes / (stats.averageViewersPerStream * stats.averageStreamDuration)) * 100)
        : 0,
      revenuePerMinute: stats.totalViewerMinutes > 0
        ? (stats.totalRevenue / stats.totalViewerMinutes).toFixed(2)
        : 0,
      giftsPerStream: stats.totalLiveStreams > 0
        ? (stats.totalGiftsReceived / stats.totalLiveStreams).toFixed(1)
        : 0,
      followerConversionRate: stats.totalViewerMinutes > 0
        ? ((stats.followerGainFromStreams / stats.totalViewerMinutes) * 100).toFixed(3)
        : 0,
      engagementScore: stats.averageEngagementScore,
    };

    return engagement;
  }
}

const service = new HostStreamStatsService();

router.get(
  "/users/me/stream-stats",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const hostId = (req as any).userId;
      const stats = await service.getStats(hostId);

      return success(res, 200, stats, "Yayıncı istatistikleri getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Yayıncı istatistikleri getirilemedi");
    }
  }
);

router.get(
  "/users/:userId/stream-stats",
  async (req: Request, res: Response) => {
    try {
      const { userId } = req.params;
      const stats = await service.getStats(userId);

      return success(res, 200, stats, "Yayıncı istatistikleri getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Yayıncı istatistikleri getirilemedi");
    }
  }
);

router.patch(
  "/users/me/stream-stats",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const hostId = (req as any).userId;

      const stats = await service.updateStats(hostId, req.body);

      return success(res, 200, stats, "Yayıncı istatistikleri güncellendi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Yayıncı istatistikleri güncellenemedi");
    }
  }
);

router.post(
  "/users/me/stream-stats/increment",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const hostId = (req as any).userId;

      const stats = await service.incrementStats(hostId, req.body);

      return success(res, 200, stats, "Yayıncı istatistikleri artırıldı");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Yayıncı istatistikleri artırılamadı");
    }
  }
);

router.get(
  "/stream-stats/leaderboard",
  async (req: Request, res: Response) => {
    try {
      const sortBy =
        (req.query.sortBy as any) || "revenue";
      const limit = Math.min(parseInt(req.query.limit as string) || 20, 100);

      const leaderboard = await service.getLeaderboard(sortBy, limit);

      return success(res, 200, leaderboard, "Leaderboard getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Leaderboard getirilemedi");
    }
  }
);

router.get(
  "/users/:userId/stream-stats/rank",
  async (req: Request, res: Response) => {
    try {
      const { userId } = req.params;
      const sortBy =
        (req.query.sortBy as any) || "revenue";

      const rank = await service.getHostRank(userId, sortBy);

      return success(res, 200, { rank }, "Kullanıcı sıralaması getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Kullanıcı sıralaması getirilemedi");
    }
  }
);

router.get(
  "/users/me/stream-stats/monthly",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const hostId = (req as any).userId;
      const stats = await service.getMonthlyStats(hostId);

      return success(res, 200, stats, "Aylık istatistikler getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Aylık istatistikler getirilemedi");
    }
  }
);

router.get(
  "/users/me/stream-stats/engagement",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const hostId = (req as any).userId;
      const engagement = await service.getEngagementAnalysis(hostId);

      return success(res, 200, engagement, "Engagement analizi getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Engagement analizi getirilemedi");
    }
  }
);

export { router as hostStreamStatsRouter };
