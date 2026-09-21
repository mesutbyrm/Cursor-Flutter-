import { Router, Request, Response } from "express";
import { prisma } from "../lib/prisma";
import { requireAuth } from "../middleware/requireAuth";
import { fail, success } from "../lib/response";

const router = Router();

class StreamQualityService {
  async recordQualityMetrics(
    streamId: string,
    userId: string | null,
    data: {
      bitrate: number;
      fps: number;
      resolution: string;
      encoder?: string;
      packetLoss: number;
      latency: number;
      bufferCount: number;
    }
  ) {
    return prisma.streamQualityMetrics.create({
      data: {
        streamId,
        userId,
        bitrate: data.bitrate,
        fps: data.fps,
        resolution: data.resolution,
        encoder: data.encoder,
        packetLoss: data.packetLoss,
        latency: data.latency,
        bufferCount: data.bufferCount,
      },
    });
  }

  async getQualityMetrics(streamId: string, limit = 100, offset = 0) {
    const metrics = await prisma.streamQualityMetrics.findMany({
      where: { streamId },
      orderBy: { recordedAt: "desc" },
      take: limit,
      skip: offset,
    });

    return metrics;
  }

  async getAverageQuality(streamId: string, hours = 1) {
    const since = new Date(Date.now() - hours * 60 * 60 * 1000);

    const metrics = await prisma.streamQualityMetrics.findMany({
      where: {
        streamId,
        recordedAt: { gte: since },
      },
    });

    if (metrics.length === 0) {
      return null;
    }

    const avg = {
      avgBitrate:
        metrics.reduce((sum, m) => sum + m.bitrate, 0) / metrics.length,
      avgFps: metrics.reduce((sum, m) => sum + m.fps, 0) / metrics.length,
      avgPacketLoss:
        metrics.reduce((sum, m) => sum + m.packetLoss, 0) / metrics.length,
      avgLatency:
        metrics.reduce((sum, m) => sum + m.latency, 0) / metrics.length,
      avgBufferCount:
        metrics.reduce((sum, m) => sum + m.bufferCount, 0) / metrics.length,
      minBitrate: Math.min(...metrics.map((m) => m.bitrate)),
      maxBitrate: Math.max(...metrics.map((m) => m.bitrate)),
      minLatency: Math.min(...metrics.map((m) => m.latency)),
      maxLatency: Math.max(...metrics.map((m) => m.latency)),
      count: metrics.length,
    };

    return avg;
  }

  async getQualityScore(streamId: string, hours = 1) {
    const avg = await this.getAverageQuality(streamId, hours);
    if (!avg) return null;

    let score = 100;

    if (avg.avgBitrate < 500) score -= 20;
    else if (avg.avgBitrate < 1000) score -= 10;

    if (avg.avgFps < 24) score -= 20;
    else if (avg.avgFps < 30) score -= 10;

    if (avg.avgLatency > 500) score -= 20;
    else if (avg.avgLatency > 300) score -= 10;

    if (avg.avgPacketLoss > 2) score -= 20;
    else if (avg.avgPacketLoss > 0.5) score -= 10;

    return Math.max(0, Math.min(100, score));
  }

  async getUserQualityReport(streamId: string, userId: string) {
    const metrics = await prisma.streamQualityMetrics.findMany({
      where: { streamId, userId },
      orderBy: { recordedAt: "desc" },
      take: 50,
    });

    if (metrics.length === 0) return null;

    return {
      userId,
      metricsCount: metrics.length,
      avgBitrate: metrics.reduce((sum, m) => sum + m.bitrate, 0) / metrics.length,
      avgFps: metrics.reduce((sum, m) => sum + m.fps, 0) / metrics.length,
      avgPacketLoss:
        metrics.reduce((sum, m) => sum + m.packetLoss, 0) / metrics.length,
      avgLatency: metrics.reduce((sum, m) => sum + m.latency, 0) / metrics.length,
      avgBufferCount:
        metrics.reduce((sum, m) => sum + m.bufferCount, 0) / metrics.length,
      resolutions: [...new Set(metrics.map((m) => m.resolution))],
      lastRecordedAt: metrics[0].recordedAt,
    };
  }
}

const service = new StreamQualityService();

router.post(
  "/video-streams/:streamId/quality/metrics",
  async (req: Request, res: Response) => {
    try {
      const { streamId } = req.params;
      const userId = (req as any).userId || null;
      const {
        bitrate,
        fps,
        resolution,
        encoder,
        packetLoss,
        latency,
        bufferCount,
      } = req.body;

      if (
        bitrate === undefined ||
        fps === undefined ||
        !resolution ||
        packetLoss === undefined ||
        latency === undefined ||
        bufferCount === undefined
      ) {
        return fail(res, 400, "VALIDATION_ERROR", "Gerekli alanlar eksik");
      }

      const metrics = await service.recordQualityMetrics(streamId, userId, {
        bitrate,
        fps,
        resolution,
        encoder,
        packetLoss,
        latency,
        bufferCount,
      });

      return success(res, 201, metrics, "Kalite metrikleri kaydedildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Kalite metrikleri kaydedilemedi");
    }
  }
);

router.get(
  "/video-streams/:streamId/quality/metrics",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { streamId } = req.params;
      const limit = Math.min(parseInt(req.query.limit as string) || 100, 500);
      const offset = parseInt(req.query.offset as string) || 0;

      const metrics = await service.getQualityMetrics(streamId, limit, offset);

      return success(res, 200, metrics, "Kalite metrikleri getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Kalite metrikleri getirilemedi");
    }
  }
);

router.get(
  "/video-streams/:streamId/quality/average",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { streamId } = req.params;
      const hours = parseInt(req.query.hours as string) || 1;

      const avg = await service.getAverageQuality(streamId, hours);

      if (!avg) {
        return success(res, 200, null, "Kalite verisi bulunamadı");
      }

      return success(res, 200, avg, "Ortalama kalite getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Ortalama kalite getirilemedi");
    }
  }
);

router.get(
  "/video-streams/:streamId/quality/score",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { streamId } = req.params;
      const hours = parseInt(req.query.hours as string) || 1;

      const score = await service.getQualityScore(streamId, hours);

      return success(
        res,
        200,
        { qualityScore: score },
        "Kalite skoru getirildi"
      );
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Kalite skoru getirilemedi");
    }
  }
);

router.get(
  "/video-streams/:streamId/quality/user/:userId",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { streamId, userId } = req.params;

      const report = await service.getUserQualityReport(streamId, userId);

      if (!report) {
        return success(res, 200, null, "Kullanıcı kalite verisi bulunamadı");
      }

      return success(res, 200, report, "Kullanıcı kalite raporu getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Kullanıcı kalite raporu getirilemedi");
    }
  }
);

export { router as streamQualityRouter };
