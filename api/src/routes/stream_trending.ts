import { Router, Request, Response } from "express";
import { prisma } from "../lib/prisma";
import { requireAuth } from "../middleware/requireAuth";
import { fail, success } from "../lib/response";

const router = Router();

class StreamTrendingService {
  async recordTrendingData(
    streamId: string,
    data: {
      viewerCount: number;
      giftCount: number;
      messageCount: number;
      engagementScore: number;
      period?: string;
    }
  ) {
    const trendingScore = this.calculateTrendingScore(data);

    return prisma.streamTrendingData.create({
      data: {
        streamId,
        viewerCount: data.viewerCount,
        giftCount: data.giftCount,
        messageCount: data.messageCount,
        engagementScore: data.engagementScore,
        trendingScore,
        period: data.period || "24h",
      },
    });
  }

  calculateTrendingScore(data: {
    viewerCount: number;
    giftCount: number;
    messageCount: number;
    engagementScore: number;
  }): number {
    const viewerScore = Math.min(data.viewerCount / 100, 30);
    const giftScore = Math.min(data.giftCount * 2, 30);
    const messageScore = Math.min(data.messageCount / 10, 20);
    const engagementMultiplier = data.engagementScore / 100;

    const baseScore = viewerScore + giftScore + messageScore;
    return Math.round(baseScore * engagementMultiplier);
  }

  async getTrendingStreams(period = "24h", limit = 20) {
    const data = await prisma.streamTrendingData.findMany({
      where: { period },
      orderBy: { trendingScore: "desc" },
      take: limit,
      distinct: ["streamId"],
    });

    return data;
  }

  async getStreamTrendingData(streamId: string, period = "24h", limit = 50) {
    const data = await prisma.streamTrendingData.findMany({
      where: { streamId, period },
      orderBy: { recordedAt: "desc" },
      take: limit,
    });

    return data;
  }

  async calculateTrendingRank(streamId: string, period = "24h") {
    const allStreams = await prisma.streamTrendingData.groupBy({
      by: ["streamId"],
      where: { period },
      _max: { trendingScore: true },
      orderBy: { _max: { trendingScore: "desc" } },
    });

    const rank = allStreams.findIndex((s) => s.streamId === streamId) + 1;

    return rank > 0 ? rank : null;
  }

  async getTopStreams(
    limit = 10,
    period = "24h"
  ): Promise<
    Array<{
      streamId: string;
      trendingScore: number;
      rank: number;
      viewerCount: number;
      giftCount: number;
    }>
  > {
    const latestDataPerStream = await prisma.streamTrendingData.findMany({
      where: { period },
      distinct: ["streamId"],
      orderBy: { recordedAt: "desc" },
    });

    const topStreams = latestDataPerStream
      .sort((a, b) => b.trendingScore - a.trendingScore)
      .slice(0, limit)
      .map((data, index) => ({
        streamId: data.streamId,
        trendingScore: data.trendingScore,
        rank: index + 1,
        viewerCount: data.viewerCount,
        giftCount: data.giftCount,
      }));

    return topStreams;
  }

  async getStreamTrend(streamId: string, period = "24h") {
    const data = await prisma.streamTrendingData.findMany({
      where: { streamId, period },
      orderBy: { recordedAt: "asc" },
      take: 100,
    });

    if (data.length < 2) {
      return { trend: "stable", change: 0 };
    }

    const firstScore = data[0].trendingScore;
    const lastScore = data[data.length - 1].trendingScore;
    const change = ((lastScore - firstScore) / firstScore) * 100;

    let trend = "stable";
    if (change > 10) trend = "rising";
    else if (change < -10) trend = "falling";

    return { trend, change: Math.round(change * 100) / 100, data };
  }

  async getRecommendedStreams(userId: string | null, limit = 10) {
    const allTrending = await this.getTrendingStreams("24h", 100);

    let filtered = allTrending;

    if (userId) {
      const userViewHistory = await prisma.streamViewerSession
        .findMany({
          where: { userId },
          select: { streamId: true },
          distinct: ["streamId"],
          take: 20,
        })
        .catch(() => []);

      const viewedStreamIds = new Set(userViewHistory.map((v) => v.streamId));
      filtered = filtered.filter((s) => !viewedStreamIds.has(s.streamId));
    }

    return filtered.slice(0, limit);
  }
}

const service = new StreamTrendingService();

router.post(
  "/video-streams/:streamId/trending/record",
  async (req: Request, res: Response) => {
    try {
      const { streamId } = req.params;
      const { viewerCount, giftCount, messageCount, engagementScore, period } =
        req.body;

      if (
        viewerCount === undefined ||
        giftCount === undefined ||
        messageCount === undefined ||
        engagementScore === undefined
      ) {
        return fail(res, 400, "VALIDATION_ERROR", "Gerekli alanlar eksik");
      }

      const data = await service.recordTrendingData(streamId, {
        viewerCount,
        giftCount,
        messageCount,
        engagementScore,
        period,
      });

      return success(res, 201, data, "Trending verisi kaydedildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Trending verisi kaydedilemedi");
    }
  }
);

router.get(
  "/video-streams/trending",
  async (req: Request, res: Response) => {
    try {
      const period = (req.query.period as string) || "24h";
      const limit = Math.min(parseInt(req.query.limit as string) || 20, 100);

      const trending = await service.getTrendingStreams(period, limit);

      return success(res, 200, trending, "Trending yayınlar getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Trending yayınlar getirilemedi");
    }
  }
);

router.get(
  "/video-streams/:streamId/trending/data",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { streamId } = req.params;
      const period = (req.query.period as string) || "24h";
      const limit = Math.min(parseInt(req.query.limit as string) || 50, 200);

      const data = await service.getStreamTrendingData(streamId, period, limit);

      return success(res, 200, data, "Trending verisi getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Trending verisi getirilemedi");
    }
  }
);

router.get(
  "/video-streams/:streamId/trending/rank",
  async (req: Request, res: Response) => {
    try {
      const { streamId } = req.params;
      const period = (req.query.period as string) || "24h";

      const rank = await service.calculateTrendingRank(streamId, period);

      return success(res, 200, { rank }, "Trending sıralaması getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Trending sıralaması getirilemedi");
    }
  }
);

router.get(
  "/video-streams/trending/top",
  async (req: Request, res: Response) => {
    try {
      const limit = Math.min(parseInt(req.query.limit as string) || 10, 50);
      const period = (req.query.period as string) || "24h";

      const topStreams = await service.getTopStreams(limit, period);

      return success(res, 200, topStreams, "En iyi yayınlar getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "En iyi yayınlar getirilemedi");
    }
  }
);

router.get(
  "/video-streams/:streamId/trending/trend",
  async (req: Request, res: Response) => {
    try {
      const { streamId } = req.params;
      const period = (req.query.period as string) || "24h";

      const trend = await service.getStreamTrend(streamId, period);

      return success(res, 200, trend, "Trending trendi getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Trending trendi getirilemedi");
    }
  }
);

router.get(
  "/video-streams/trending/recommended",
  async (req: Request, res: Response) => {
    try {
      const userId = (req as any).userId || null;
      const limit = Math.min(parseInt(req.query.limit as string) || 10, 50);

      const recommended = await service.getRecommendedStreams(userId, limit);

      return success(
        res,
        200,
        recommended,
        "Önerilen yayınlar getirildi"
      );
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Önerilen yayınlar getirilemedi");
    }
  }
);

export { router as streamTrendingRouter };
