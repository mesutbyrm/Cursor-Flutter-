import { Router, Request, Response } from "express";
import { PrismaClient } from "@prisma/client";
import { requireAuth } from "../middleware/requireAuth";

const prisma = new PrismaClient();
const router = Router();

class LiveStreamAnalyticsService {
  async getOrCreateAnalytics(streamId: string) {
    return prisma.liveStreamAnalytics.upsert({
      where: { streamId },
      create: { streamId },
      update: {},
    });
  }

  async getStreamAnalytics(streamId: string) {
    return prisma.liveStreamAnalytics.findUnique({
      where: { streamId },
    });
  }

  async recordViewerSession(streamId: string, userId: string, data: {
    deviceType?: string;
    country?: string;
    appVersion?: string;
  }) {
    return prisma.streamViewerSession.create({
      data: {
        streamId,
        userId,
        deviceType: data.deviceType,
        country: data.country,
        appVersion: data.appVersion,
      },
    });
  }

  async endViewerSession(sessionId: string, watchDurationSeconds: number) {
    return prisma.streamViewerSession.update({
      where: { id: sessionId },
      data: {
        leftAt: new Date(),
        watchDurationSeconds,
      },
    });
  }

  async getViewerSessions(streamId: string, limit = 100) {
    return prisma.streamViewerSession.findMany({
      where: { streamId },
      take: limit,
      orderBy: { joinedAt: "desc" },
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

  async updateAnalytics(streamId: string, data: Record<string, any>) {
    return prisma.liveStreamAnalytics.update({
      where: { streamId },
      data: {
        ...data,
        updatedAt: new Date(),
      },
    });
  }

  async recordGift(streamId: string, userId: string, giftValue: number) {
    const session = await prisma.streamViewerSession.findFirst({
      where: { streamId, userId },
      orderBy: { joinedAt: "desc" },
    });

    if (session) {
      await prisma.streamViewerSession.update({
        where: { id: session.id },
        data: {
          isGifter: true,
          giftCount: { increment: 1 },
          totalGiftValue: { increment: giftValue },
        },
      });
    }

    const analytics = await this.getStreamAnalytics(streamId);
    if (analytics) {
      await this.updateAnalytics(streamId, {
        totalGiftsCount: analytics.totalGiftsCount + 1,
        totalGiftValue: analytics.totalGiftValue + giftValue,
      });
    }
  }

  async recordMessage(streamId: string, userId: string) {
    const session = await prisma.streamViewerSession.findFirst({
      where: { streamId, userId },
      orderBy: { joinedAt: "desc" },
    });

    if (session) {
      await prisma.streamViewerSession.update({
        where: { id: session.id },
        data: { messageCount: { increment: 1 } },
      });
    }

    const analytics = await this.getStreamAnalytics(streamId);
    if (analytics) {
      await this.updateAnalytics(streamId, {
        totalMessagesCount: analytics.totalMessagesCount + 1,
      });
    }
  }

  async recordLike(streamId: string, userId: string) {
    const session = await prisma.streamViewerSession.findFirst({
      where: { streamId, userId },
      orderBy: { joinedAt: "desc" },
    });

    if (session) {
      await prisma.streamViewerSession.update({
        where: { id: session.id },
        data: { likeCount: { increment: 1 } },
      });
    }
  }

  async calculateEngagementScore(streamId: string): Promise<number> {
    const analytics = await this.getStreamAnalytics(streamId);
    if (!analytics) return 0;

    let score = 0;
    score += Math.min(analytics.totalViewers * 2, 100);
    score += Math.min(analytics.totalMessagesCount * 0.5, 100);
    score += Math.min(analytics.totalGiftValue / 100, 100);
    score += Math.min(analytics.totalMinutesWatched / 10, 100);

    return Math.round(score / 4);
  }

  async calculateRetentionRate(streamId: string): Promise<number> {
    const sessions = await prisma.streamViewerSession.findMany({
      where: { streamId },
    });

    if (sessions.length === 0) return 0;

    const completedSessions = sessions.filter((s) => s.leftAt !== null).length;
    return Math.round((completedSessions / sessions.length) * 100);
  }

  async getStreamStats(streamId: string) {
    const sessions = await prisma.streamViewerSession.findMany({
      where: { streamId },
    });

    const totalViewers = new Set(sessions.map((s) => s.userId)).size;
    const totalDuration = sessions.reduce((sum, s) => sum + s.watchDurationSeconds, 0);
    const avgDuration = totalViewers > 0 ? totalDuration / totalViewers : 0;
    const totalGifts = sessions.reduce((sum, s) => sum + s.totalGiftValue, 0);
    const giftCount = sessions.reduce((sum, s) => sum + s.giftCount, 0);
    const messageCount = sessions.reduce((sum, s) => sum + s.messageCount, 0);

    const gifters = sessions.filter((s) => s.isGifter).length;
    const peakViewers = Math.max(
      ...sessions.map((s) => (s.leftAt ? 0 : 1)),
      0
    );

    return {
      totalViewers,
      totalDuration: Math.round(totalDuration / 60),
      avgDuration: Math.round(avgDuration / 60),
      totalGifts,
      giftCount,
      messageCount,
      gifters,
      peakViewers,
    };
  }

  async getViewerDemographics(streamId: string) {
    const sessions = await prisma.streamViewerSession.findMany({
      where: { streamId },
    });

    const demographics = {
      byCountry: new Map<string, number>(),
      byDevice: new Map<string, number>(),
      byAppVersion: new Map<string, number>(),
    };

    sessions.forEach((session) => {
      if (session.country) {
        demographics.byCountry.set(
          session.country,
          (demographics.byCountry.get(session.country) || 0) + 1
        );
      }
      if (session.deviceType) {
        demographics.byDevice.set(
          session.deviceType,
          (demographics.byDevice.get(session.deviceType) || 0) + 1
        );
      }
      if (session.appVersion) {
        demographics.byAppVersion.set(
          session.appVersion,
          (demographics.byAppVersion.get(session.appVersion) || 0) + 1
        );
      }
    });

    return {
      countries: Object.fromEntries(demographics.byCountry),
      devices: Object.fromEntries(demographics.byDevice),
      appVersions: Object.fromEntries(demographics.byAppVersion),
    };
  }

  async getTopGifters(streamId: string, limit = 10) {
    return prisma.streamViewerSession.findMany({
      where: { streamId, isGifter: true },
      take: limit,
      orderBy: { totalGiftValue: "desc" },
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

  async generatePerformanceReport(streamId: string) {
    const analytics = await this.getStreamAnalytics(streamId);
    if (!analytics) return null;

    const stats = await this.getStreamStats(streamId);
    const engagementScore = await this.calculateEngagementScore(streamId);
    const retentionRate = await this.calculateRetentionRate(streamId);
    const demographics = await this.getViewerDemographics(streamId);
    const topGifters = await this.getTopGifters(streamId, 5);

    return {
      streamId,
      overview: {
        totalViewers: stats.totalViewers,
        totalDuration: stats.totalDuration,
        avgViewerDuration: Math.round(stats.avgDuration),
        peakViewers: stats.peakViewers,
      },
      engagement: {
        engagementScore,
        retentionRate,
        messageCount: stats.messageCount,
        likeCount: sessions?.reduce((sum, s) => sum + s.likeCount, 0) || 0,
      },
      monetization: {
        giftCount: stats.giftCount,
        totalGiftValue: stats.totalGifts,
        avgGiftValue: stats.giftCount > 0 ? stats.totalGifts / stats.giftCount : 0,
        topGifters,
      },
      demographics,
      updatedAt: analytics.updatedAt,
    };
  }
}

const service = new LiveStreamAnalyticsService();
const sessions = new Map<string, any>();

router.post("/video-streams/:streamId/session/start", requireAuth, async (req: Request, res: Response) => {
  try {
    const { streamId } = req.params;
    const userId = (req as any).user?.id;
    const { deviceType, country, appVersion } = req.body;

    if (!userId) {
      return res.status(401).json({ success: false, message: "Yetkilendirme gerekli" });
    }

    const session = await service.recordViewerSession(streamId, userId, {
      deviceType,
      country,
      appVersion,
    });

    sessions.set(session.id, { startTime: Date.now(), streamId, userId });

    return res.status(201).json({
      success: true,
      data: session,
    });
  } catch (error) {
    console.error("recordViewerSession error:", error);
    return res.status(500).json({
      success: false,
      message: "Oturum başlatılamadı",
    });
  }
});

router.post("/video-streams/:streamId/session/:sessionId/end", requireAuth, async (req: Request, res: Response) => {
  try {
    const { sessionId } = req.params;
    const { watchDuration } = req.body;

    const duration = watchDuration || Math.round((Date.now() - (sessions.get(sessionId)?.startTime || Date.now())) / 1000);

    const session = await service.endViewerSession(sessionId, duration);
    sessions.delete(sessionId);

    return res.status(200).json({
      success: true,
      data: session,
    });
  } catch (error) {
    console.error("endViewerSession error:", error);
    return res.status(500).json({
      success: false,
      message: "Oturum sonlandırılamadı",
    });
  }
});

router.get("/video-streams/:streamId/analytics", async (req: Request, res: Response) => {
  try {
    const { streamId } = req.params;

    const analytics = await service.getOrCreateAnalytics(streamId);

    return res.status(200).json({
      success: true,
      data: analytics,
    });
  } catch (error) {
    console.error("getStreamAnalytics error:", error);
    return res.status(500).json({
      success: false,
      message: "Analitik alınamadı",
    });
  }
});

router.get("/video-streams/:streamId/viewer-sessions", async (req: Request, res: Response) => {
  try {
    const { streamId } = req.params;
    const limit = parseInt(req.query.limit as string) || 100;

    const viewerSessions = await service.getViewerSessions(streamId, limit);

    return res.status(200).json({
      success: true,
      data: viewerSessions,
    });
  } catch (error) {
    console.error("getViewerSessions error:", error);
    return res.status(500).json({
      success: false,
      message: "Viewer oturumları alınamadı",
    });
  }
});

router.post("/video-streams/:streamId/analytics/gift", requireAuth, async (req: Request, res: Response) => {
  try {
    const { streamId } = req.params;
    const userId = (req as any).user?.id;
    const { giftValue } = req.body;

    if (!userId) {
      return res.status(401).json({ success: false, message: "Yetkilendirme gerekli" });
    }

    await service.recordGift(streamId, userId, giftValue);

    return res.status(200).json({
      success: true,
      message: "Hediye kaydedildi",
    });
  } catch (error) {
    console.error("recordGift error:", error);
    return res.status(500).json({
      success: false,
      message: "Hediye kaydedilemedi",
    });
  }
});

router.post("/video-streams/:streamId/analytics/message", requireAuth, async (req: Request, res: Response) => {
  try {
    const { streamId } = req.params;
    const userId = (req as any).user?.id;

    if (!userId) {
      return res.status(401).json({ success: false, message: "Yetkilendirme gerekli" });
    }

    await service.recordMessage(streamId, userId);

    return res.status(200).json({
      success: true,
      message: "Mesaj kaydedildi",
    });
  } catch (error) {
    console.error("recordMessage error:", error);
    return res.status(500).json({
      success: false,
      message: "Mesaj kaydedilemedi",
    });
  }
});

router.post("/video-streams/:streamId/analytics/like", requireAuth, async (req: Request, res: Response) => {
  try {
    const { streamId } = req.params;
    const userId = (req as any).user?.id;

    if (!userId) {
      return res.status(401).json({ success: false, message: "Yetkilendirme gerekli" });
    }

    await service.recordLike(streamId, userId);

    return res.status(200).json({
      success: true,
      message: "Beğeni kaydedildi",
    });
  } catch (error) {
    console.error("recordLike error:", error);
    return res.status(500).json({
      success: false,
      message: "Beğeni kaydedilemedi",
    });
  }
});

router.get("/video-streams/:streamId/stats", async (req: Request, res: Response) => {
  try {
    const { streamId } = req.params;

    const stats = await service.getStreamStats(streamId);

    return res.status(200).json({
      success: true,
      data: stats,
    });
  } catch (error) {
    console.error("getStreamStats error:", error);
    return res.status(500).json({
      success: false,
      message: "İstatistikler alınamadı",
    });
  }
});

router.get("/video-streams/:streamId/top-gifters", async (req: Request, res: Response) => {
  try {
    const { streamId } = req.params;
    const limit = parseInt(req.query.limit as string) || 10;

    const topGifters = await service.getTopGifters(streamId, limit);

    return res.status(200).json({
      success: true,
      data: topGifters,
    });
  } catch (error) {
    console.error("getTopGifters error:", error);
    return res.status(500).json({
      success: false,
      message: "En çok hediye verenler alınamadı",
    });
  }
});

router.get("/video-streams/:streamId/demographics", async (req: Request, res: Response) => {
  try {
    const { streamId } = req.params;

    const demographics = await service.getViewerDemographics(streamId);

    return res.status(200).json({
      success: true,
      data: demographics,
    });
  } catch (error) {
    console.error("getViewerDemographics error:", error);
    return res.status(500).json({
      success: false,
      message: "Demografik bilgiler alınamadı",
    });
  }
});

router.get("/video-streams/:streamId/performance-report", async (req: Request, res: Response) => {
  try {
    const { streamId } = req.params;

    const report = await service.generatePerformanceReport(streamId);

    if (!report) {
      return res.status(404).json({
        success: false,
        message: "Performans raporu bulunamadı",
      });
    }

    return res.status(200).json({
      success: true,
      data: report,
    });
  } catch (error) {
    console.error("generatePerformanceReport error:", error);
    return res.status(500).json({
      success: false,
      message: "Performans raporu oluşturulamadı",
    });
  }
});

export const liveStreamAnalyticsRouter = router;
