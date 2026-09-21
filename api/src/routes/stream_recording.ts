import { Router, Request, Response } from "express";
import { prisma } from "../lib/prisma";
import { requireAuth } from "../middleware/requireAuth";
import { fail, success } from "../lib/response";

const router = Router();

class StreamRecordingService {
  async createRecording(
    streamId: string,
    hostId: string,
    data: {
      recordingUrl: string;
      thumbnailUrl?: string;
      duration: number;
      fileSize: number;
      title?: string;
      description?: string;
      tags?: string[];
      isPublic?: boolean;
      expiresAt?: Date;
    }
  ) {
    return prisma.streamRecording.create({
      data: {
        streamId,
        hostId,
        recordingUrl: data.recordingUrl,
        thumbnailUrl: data.thumbnailUrl,
        duration: data.duration,
        fileSize: data.fileSize,
        title: data.title,
        description: data.description,
        tags: data.tags || [],
        isPublic: data.isPublic ?? false,
        startedAt: new Date(),
        expiresAt: data.expiresAt,
      },
      include: {
        host: { select: { id: true, displayName: true, avatarUrl: true } },
      },
    });
  }

  async endRecording(recordingId: string) {
    return prisma.streamRecording.update({
      where: { id: recordingId },
      data: { endedAt: new Date() },
    });
  }

  async getRecordings(
    hostId: string,
    limit = 20,
    offset = 0,
    isPublic?: boolean
  ) {
    const where: any = { hostId };
    if (isPublic !== undefined) {
      where.isPublic = isPublic;
    }

    const [recordings, total] = await Promise.all([
      prisma.streamRecording.findMany({
        where,
        orderBy: { createdAt: "desc" },
        take: limit,
        skip: offset,
        include: {
          host: { select: { id: true, displayName: true, avatarUrl: true } },
        },
      }),
      prisma.streamRecording.count({ where }),
    ]);

    return { recordings, total, hasMore: offset + limit < total };
  }

  async getPublicRecordings(limit = 20, offset = 0) {
    const [recordings, total] = await Promise.all([
      prisma.streamRecording.findMany({
        where: { isPublic: true, isArchived: false },
        orderBy: { createdAt: "desc" },
        take: limit,
        skip: offset,
        include: {
          host: { select: { id: true, displayName: true, avatarUrl: true } },
        },
      }),
      prisma.streamRecording.count({
        where: { isPublic: true, isArchived: false },
      }),
    ]);

    return { recordings, total, hasMore: offset + limit < total };
  }

  async getRecordingStats(hostId: string) {
    const recordings = await prisma.streamRecording.findMany({
      where: { hostId },
    });

    const totalViewCount = recordings.reduce((sum, r) => sum + r.viewCount, 0);
    const totalDuration = recordings.reduce((sum, r) => sum + r.duration, 0);
    const totalFileSize = recordings.reduce((sum, r) => sum + r.fileSize, 0);

    return {
      totalRecordings: recordings.length,
      totalViewCount,
      totalDuration,
      totalFileSize,
      publicRecordings: recordings.filter((r) => r.isPublic).length,
      archivedRecordings: recordings.filter((r) => r.isArchived).length,
      avgDuration:
        recordings.length > 0
          ? Math.round(totalDuration / recordings.length)
          : 0,
      avgViewCount:
        recordings.length > 0
          ? Math.round(totalViewCount / recordings.length)
          : 0,
    };
  }

  async updateRecordingVisibility(
    recordingId: string,
    isPublic: boolean
  ) {
    return prisma.streamRecording.update({
      where: { id: recordingId },
      data: { isPublic },
    });
  }

  async incrementViewCount(recordingId: string) {
    return prisma.streamRecording.update({
      where: { id: recordingId },
      data: { viewCount: { increment: 1 } },
    });
  }

  async archiveRecording(recordingId: string) {
    return prisma.streamRecording.update({
      where: { id: recordingId },
      data: { isArchived: true },
    });
  }

  async deleteExpiredRecordings() {
    const now = new Date();
    const deleted = await prisma.streamRecording.deleteMany({
      where: {
        expiresAt: { lt: now },
      },
    });

    return deleted.count;
  }

  async searchRecordings(hostId: string, query: string, limit = 20) {
    return prisma.streamRecording.findMany({
      where: {
        hostId,
        OR: [
          { title: { contains: query, mode: "insensitive" } },
          { description: { contains: query, mode: "insensitive" } },
          { tags: { hasSome: [query] } },
        ],
      },
      orderBy: { createdAt: "desc" },
      take: limit,
    });
  }
}

const service = new StreamRecordingService();

router.post(
  "/video-streams/:streamId/recording/start",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { streamId } = req.params;
      const hostId = (req as any).userId;
      const {
        recordingUrl,
        thumbnailUrl,
        duration,
        fileSize,
        title,
        description,
        tags,
        isPublic,
        expiresAt,
      } = req.body;

      if (!recordingUrl || duration === undefined || fileSize === undefined) {
        return fail(res, 400, "VALIDATION_ERROR", "Gerekli alanlar eksik");
      }

      const recording = await service.createRecording(
        streamId,
        hostId,
        {
          recordingUrl,
          thumbnailUrl,
          duration,
          fileSize,
          title,
          description,
          tags,
          isPublic,
          expiresAt: expiresAt ? new Date(expiresAt) : undefined,
        }
      );

      return success(res, 201, recording, "Kayıt başlatıldı");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Kayıt başlatılamadı");
    }
  }
);

router.patch(
  "/video-streams/recording/:recordingId/end",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { recordingId } = req.params;

      const recording = await service.endRecording(recordingId);

      return success(res, 200, recording, "Kayıt tamamlandı");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Kayıt tamamlanamadı");
    }
  }
);

router.get(
  "/users/:userId/recordings",
  async (req: Request, res: Response) => {
    try {
      const { userId } = req.params;
      const limit = Math.min(parseInt(req.query.limit as string) || 20, 100);
      const offset = parseInt(req.query.offset as string) || 0;
      const isPublic = req.query.isPublic === "true" ? true : undefined;

      const result = await service.getRecordings(userId, limit, offset, isPublic);

      return success(res, 200, result, "Kayıtlar getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Kayıtlar getirilemedi");
    }
  }
);

router.get(
  "/recordings/public",
  async (req: Request, res: Response) => {
    try {
      const limit = Math.min(parseInt(req.query.limit as string) || 20, 100);
      const offset = parseInt(req.query.offset as string) || 0;

      const result = await service.getPublicRecordings(limit, offset);

      return success(res, 200, result, "Herkese açık kayıtlar getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Herkese açık kayıtlar getirilemedi");
    }
  }
);

router.get(
  "/users/:userId/recordings/stats",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { userId } = req.params;

      const stats = await service.getRecordingStats(userId);

      return success(res, 200, stats, "Kayıt istatistikleri getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Kayıt istatistikleri getirilemedi");
    }
  }
);

router.patch(
  "/recordings/:recordingId/visibility",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { recordingId } = req.params;
      const { isPublic } = req.body;

      if (isPublic === undefined) {
        return fail(res, 400, "VALIDATION_ERROR", "isPublic gerekli");
      }

      const recording = await service.updateRecordingVisibility(
        recordingId,
        isPublic
      );

      return success(res, 200, recording, "Kayıt görünürlüğü güncellendi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Kayıt görünürlüğü güncellenemedi");
    }
  }
);

router.post(
  "/recordings/:recordingId/view",
  async (req: Request, res: Response) => {
    try {
      const { recordingId } = req.params;

      await service.incrementViewCount(recordingId);

      return success(res, 200, null, "İzlenme sayısı artırıldı");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "İzlenme sayısı artırılamadı");
    }
  }
);

router.patch(
  "/recordings/:recordingId/archive",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { recordingId } = req.params;

      const recording = await service.archiveRecording(recordingId);

      return success(res, 200, recording, "Kayıt arşivlendi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Kayıt arşivlenemedi");
    }
  }
);

router.post(
  "/recordings/cleanup-expired",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const count = await service.deleteExpiredRecordings();

      return success(res, 200, { deletedCount: count }, "Süresi dolan kayıtlar silindi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Süresi dolan kayıtlar silinemedi");
    }
  }
);

router.get(
  "/users/:userId/recordings/search",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { userId } = req.params;
      const q = req.query.q as string;

      if (!q) {
        return fail(res, 400, "VALIDATION_ERROR", "q gerekli");
      }

      const recordings = await service.searchRecordings(userId, q);

      return success(res, 200, recordings, "Kayıtlar arandı");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Kayıtlar aranamadı");
    }
  }
);

export { router as streamRecordingRouter };
