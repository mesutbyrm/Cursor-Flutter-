import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import requireAuth from '../middleware/requireAuth';

const router = Router();
const prisma = new PrismaClient();

interface PerformanceResponse {
  ok: boolean;
  data?: any;
  error?: string;
}

// Feature 34: Performance Metrics
class PerformanceMonitoringService {
  async recordMetrics(userId: string, metrics: {
    appOpenTime?: number;
    pageLoadTime?: number;
    apiResponseTime?: number;
    batteryUsage?: number;
    dataUsage?: number;
    memoryUsage?: number;
    crashCount?: number;
  }) {
    return prisma.performanceMetrics.upsert({
      where: { userId },
      update: {
        ...metrics,
        lastUpdatedAt: new Date(),
      },
      create: {
        userId,
        ...metrics,
        lastUpdatedAt: new Date(),
      },
    });
  }

  async getMetrics(userId: string) {
    return prisma.performanceMetrics.findUnique({
      where: { userId },
    });
  }

  async getPerformanceReport(userId: string) {
    const metrics = await this.getMetrics(userId);

    if (!metrics) {
      return null;
    }

    const analysis = {
      appPerformance: metrics.appOpenTime! > 3000 ? 'slow' : 'good',
      pageLoadPerformance: metrics.pageLoadTime! > 2000 ? 'slow' : 'good',
      apiPerformance: metrics.apiResponseTime! > 1000 ? 'slow' : 'good',
      batteryEfficiency: metrics.batteryUsage! > 30 ? 'high-drain' : 'efficient',
      dataUsage: metrics.dataUsage! > 100 ? 'high' : 'normal',
      memoryUsage: metrics.memoryUsage! > 300 ? 'high' : 'normal',
      stability: metrics.crashCount! > 5 ? 'unstable' : 'stable',
    };

    const recommendations = [];
    if (analysis.appPerformance === 'slow') {
      recommendations.push('Uygulama açılış süresini iyileştirmek için arka plan işlemlerini azaltın');
    }
    if (analysis.batteryEfficiency === 'high-drain') {
      recommendations.push('Pil tasarrufu için animasyonları devre dışı bırakın');
    }
    if (analysis.dataUsage === 'high') {
      recommendations.push('Veri kullanımını azaltmak için otomatik resim indirmeyi devre dışı bırakın');
    }

    return { metrics, analysis, recommendations };
  }

  async deleteMetrics(userId: string) {
    return prisma.performanceMetrics.delete({
      where: { userId },
    });
  }
}

const service = new PerformanceMonitoringService();

router.post('/record', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const metrics = req.body;

    const recorded = await service.recordMetrics(userId, metrics);

    res.json({
      ok: true,
      data: recorded,
    } as PerformanceResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as PerformanceResponse);
  }
});

router.get('/metrics', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;

    const metrics = await service.getMetrics(userId);

    res.json({
      ok: true,
      data: metrics,
    } as PerformanceResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as PerformanceResponse);
  }
});

router.get('/report', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;

    const report = await service.getPerformanceReport(userId);

    res.json({
      ok: true,
      data: report,
    } as PerformanceResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as PerformanceResponse);
  }
});

router.delete('/metrics', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;

    await service.deleteMetrics(userId);

    res.json({
      ok: true,
      data: { deleted: true },
    } as PerformanceResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as PerformanceResponse);
  }
});

export default router;
