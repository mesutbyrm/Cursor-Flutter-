import { Router, Request, Response } from "express";
import { PrismaClient } from "@prisma/client";
import { requireAuth } from "../middleware/requireAuth";

const prisma = new PrismaClient();
const router = Router();

class AdvancedAnalyticsService {
  async getOrCreateAnalytics(roomId: string) {
    return prisma.advancedRoomAnalytics.upsert({
      where: { roomId },
      create: {
        roomId,
      },
      update: {},
    });
  }

  async getRoomAnalytics(roomId: string) {
    return prisma.advancedRoomAnalytics.findUnique({
      where: { roomId },
    });
  }

  async updateRoomAnalytics(roomId: string, data: Record<string, any>) {
    return prisma.advancedRoomAnalytics.update({
      where: { roomId },
      data: {
        ...data,
        updatedAt: new Date(),
      },
    });
  }

  async calculateEngagementScore(roomId: string) {
    const analytics = await this.getRoomAnalytics(roomId);
    if (!analytics) return 0;

    let score = 0;

    score += Math.min(analytics.totalUniqueUsers * 2, 100);
    score += Math.min(analytics.totalDurationMinutes / 10, 100);
    score += Math.min(analytics.totalMessagesCount * 0.5, 100);
    score += Math.min(analytics.weeklyActiveUsers * 3, 100);
    score += Math.min(analytics.totalGiftValue / 100, 100);

    return Math.round(score / 5);
  }

  async calculateRetentionRate(roomId: string) {
    const analytics = await this.getRoomAnalytics(roomId);
    if (!analytics || analytics.totalUniqueUsers === 0) return 0;

    const monthlyActiveUsers = analytics.monthlyActiveUsers || 0;
    const weeklyActiveUsers = analytics.weeklyActiveUsers || 0;

    const retention = ((weeklyActiveUsers / monthlyActiveUsers) * 100) || 0;
    return Math.round(retention);
  }

  async generateInsights(roomId: string) {
    const analytics = await this.getRoomAnalytics(roomId);
    if (!analytics) return [];

    const insights = [];

    if (analytics.totalUniqueUsers > 50) {
      insights.push({
        roomId,
        insightType: "user-growth",
        title: "Yüksek Kullanıcı Büyümesi",
        description: `${analytics.totalUniqueUsers} benzersiz kullanıcı var`,
        value: analytics.totalUniqueUsers,
        trend: "up",
        recommendation: "Kullanıcı deneyimini geliştirmeye devam edin",
      });
    }

    if (analytics.averageSessionDuration > 30) {
      insights.push({
        roomId,
        insightType: "engagement-high",
        title: "Yüksek Katılım",
        description: `Ortalama oturum süresi ${analytics.averageSessionDuration} dakika`,
        value: analytics.averageSessionDuration,
        trend: "up",
        recommendation: "Bu katılım seviyesini koruya devam edin",
      });
    }

    if (analytics.retentionRate < 30) {
      insights.push({
        roomId,
        insightType: "retention-low",
        title: "Düşük Tutma Oranı",
        description: `Tutma oranı %${analytics.retentionRate}`,
        value: analytics.retentionRate,
        trend: "down",
        recommendation: "Kullanıcı bağlantısını artırmak için stratejiler uygulayın",
      });
    }

    if (analytics.totalGiftValue > 10000) {
      insights.push({
        roomId,
        insightType: "monetization-strong",
        title: "Güçlü Para Kazanma",
        description: `Toplam hediye değeri ${analytics.totalGiftValue} TL`,
        value: analytics.totalGiftValue,
        trend: "up",
        recommendation: "Premium özellikleri tanıtmaya devam edin",
      });
    }

    const peakHour = analytics.peakHourTime;
    if (peakHour) {
      insights.push({
        roomId,
        insightType: "peak-hour",
        title: "En Yüksek Aktivite Saati",
        description: `En çok aktivite ${peakHour} saatinde`,
        value: analytics.peakHourUserCount,
        recommendation: "Bu saatlerde özel etkinlikler veya aktiviteler planlayın",
      });
    }

    return insights;
  }

  async saveInsights(insights: any[]) {
    if (insights.length === 0) return;

    for (const insight of insights) {
      await prisma.roomInsight.create({
        data: insight,
      });
    }
  }

  async getRoomInsights(roomId: string, limit = 20) {
    return prisma.roomInsight.findMany({
      where: { roomId, isActive: true },
      take: limit,
      orderBy: { createdAt: "desc" },
    });
  }

  async getInsightsByType(roomId: string, insightType: string) {
    return prisma.roomInsight.findMany({
      where: { roomId, insightType },
      orderBy: { createdAt: "desc" },
    });
  }

  async compareRoomsAnalytics(roomIds: string[]) {
    const analyticsArray = await Promise.all(
      roomIds.map((roomId) => this.getRoomAnalytics(roomId))
    );

    return analyticsArray.filter((a) => a !== null).sort((a, b) => (b?.totalUniqueUsers || 0) - (a?.totalUniqueUsers || 0));
  }

  async getTrendAnalysis(roomId: string, days = 30) {
    const analytics = await this.getRoomAnalytics(roomId);
    if (!analytics) return null;

    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - days);

    const insights = await prisma.roomInsight.findMany({
      where: {
        roomId,
        createdAt: { gte: cutoffDate },
      },
      orderBy: { createdAt: "asc" },
    });

    const trendsByType = new Map<string, any[]>();

    insights.forEach((insight) => {
      if (!trendsByType.has(insight.insightType)) {
        trendsByType.set(insight.insightType, []);
      }
      trendsByType.get(insight.insightType)?.push(insight);
    });

    return {
      roomId,
      period: `${days} gün`,
      trendsByType: Object.fromEntries(trendsByType),
      totalInsights: insights.length,
    };
  }

  async generatePerformanceReport(roomId: string) {
    const analytics = await this.getRoomAnalytics(roomId);
    if (!analytics) return null;

    const engagementScore = await this.calculateEngagementScore(roomId);
    const retentionRate = await this.calculateRetentionRate(roomId);

    return {
      roomId,
      summary: {
        totalSessions: analytics.totalSessions,
        totalUniqueUsers: analytics.totalUniqueUsers,
        totalDurationHours: Math.round(analytics.totalDurationMinutes / 60),
        averageSessionDuration: analytics.averageSessionDuration,
      },
      engagement: {
        engagementScore,
        retentionRate,
        weeklyActiveUsers: analytics.weeklyActiveUsers,
        monthlyActiveUsers: analytics.monthlyActiveUsers,
      },
      monetization: {
        totalGiftsCount: analytics.totalGiftsCount,
        totalGiftValue: analytics.totalGiftValue,
        averageGiftValue: analytics.totalGiftsCount > 0 ? analytics.totalGiftValue / analytics.totalGiftsCount : 0,
      },
      communication: {
        totalMessages: analytics.totalMessagesCount,
        averageMessagesPerSession: analytics.totalSessions > 0 ? analytics.totalMessagesCount / analytics.totalSessions : 0,
      },
      peakActivity: {
        peakHour: analytics.peakHourTime,
        peakHourUsers: analytics.peakHourUserCount,
        mostActiveDay: analytics.mostActiveDay,
        mostActiveDayUsers: analytics.mostActiveDayUserCount,
      },
      updatedAt: analytics.updatedAt,
    };
  }
}

const service = new AdvancedAnalyticsService();

router.get("/rooms/:roomId/analytics", async (req: Request, res: Response) => {
  try {
    const { roomId } = req.params;

    const analytics = await service.getOrCreateAnalytics(roomId);

    return res.status(200).json({
      success: true,
      data: analytics,
    });
  } catch (error) {
    console.error("getOrCreateAnalytics error:", error);
    return res.status(500).json({
      success: false,
      message: "Analitik alınamadı",
    });
  }
});

router.post("/rooms/:roomId/analytics/update", requireAuth, async (req: Request, res: Response) => {
  try {
    const { roomId } = req.params;
    const updateData = req.body;

    const analytics = await service.updateRoomAnalytics(roomId, updateData);

    return res.status(200).json({
      success: true,
      data: analytics,
    });
  } catch (error) {
    console.error("updateRoomAnalytics error:", error);
    return res.status(500).json({
      success: false,
      message: "Analitik güncellenemedi",
    });
  }
});

router.get("/rooms/:roomId/insights", async (req: Request, res: Response) => {
  try {
    const { roomId } = req.params;
    const limit = parseInt(req.query.limit as string) || 20;

    const insights = await service.getRoomInsights(roomId, limit);

    return res.status(200).json({
      success: true,
      data: insights,
    });
  } catch (error) {
    console.error("getRoomInsights error:", error);
    return res.status(500).json({
      success: false,
      message: "İçgörüler alınamadı",
    });
  }
});

router.post("/rooms/:roomId/analytics/generate-insights", requireAuth, async (req: Request, res: Response) => {
  try {
    const { roomId } = req.params;

    const insights = await service.generateInsights(roomId);
    await service.saveInsights(
      insights.map((i) => ({
        ...i,
        isActive: true,
      }))
    );

    return res.status(200).json({
      success: true,
      data: insights,
    });
  } catch (error) {
    console.error("generateInsights error:", error);
    return res.status(500).json({
      success: false,
      message: "İçgörüler oluşturulamadı",
    });
  }
});

router.get("/rooms/:roomId/performance-report", async (req: Request, res: Response) => {
  try {
    const { roomId } = req.params;

    const report = await service.generatePerformanceReport(roomId);

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

router.post("/analytics/compare-rooms", requireAuth, async (req: Request, res: Response) => {
  try {
    const { roomIds } = req.body;

    if (!Array.isArray(roomIds) || roomIds.length === 0) {
      return res.status(400).json({
        success: false,
        message: "Oda kimlikleri gerekli",
      });
    }

    const comparison = await service.compareRoomsAnalytics(roomIds);

    return res.status(200).json({
      success: true,
      data: comparison,
    });
  } catch (error) {
    console.error("compareRoomsAnalytics error:", error);
    return res.status(500).json({
      success: false,
      message: "Odalar karşılaştırılamadı",
    });
  }
});

router.get("/rooms/:roomId/trend-analysis", async (req: Request, res: Response) => {
  try {
    const { roomId } = req.params;
    const days = parseInt(req.query.days as string) || 30;

    const trend = await service.getTrendAnalysis(roomId, days);

    if (!trend) {
      return res.status(404).json({
        success: false,
        message: "Trend analizi bulunamadı",
      });
    }

    return res.status(200).json({
      success: true,
      data: trend,
    });
  } catch (error) {
    console.error("getTrendAnalysis error:", error);
    return res.status(500).json({
      success: false,
      message: "Trend analizi alınamadı",
    });
  }
});

export const advancedAnalyticsRouter = router;
