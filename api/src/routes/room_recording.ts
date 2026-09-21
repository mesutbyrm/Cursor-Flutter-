import { Router, Request, Response } from "express";
import { PrismaClient } from "@prisma/client";
import { requireAuth } from "../middleware/requireAuth";

const prisma = new PrismaClient();
const router = Router();

class RoomRecordingService {
  async startRecording(
    roomId: string,
    userId: string | null,
    data: {
      title?: string;
      description?: string;
      recordingUrl?: string;
    }
  ) {
    return prisma.roomRecording.create({
      data: {
        roomId,
        userId,
        title: data.title,
        description: data.description,
        recordingUrl: data.recordingUrl || "",
        duration: 0,
        fileSize: 0,
        startedAt: new Date(),
      },
    });
  }

  async endRecording(recordingId: string, duration: number, fileSize: number) {
    return prisma.roomRecording.update({
      where: { id: recordingId },
      data: {
        endedAt: new Date(),
        duration,
        fileSize,
      },
    });
  }

  async getRoomRecordings(roomId: string, limit = 50, includeArchived = false) {
    return prisma.roomRecording.findMany({
      where: {
        roomId,
        isArchived: includeArchived ? undefined : false,
      },
      take: limit,
      orderBy: { startedAt: "desc" },
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

  async getUserRecordings(userId: string, limit = 50) {
    return prisma.roomRecording.findMany({
      where: { userId },
      take: limit,
      orderBy: { startedAt: "desc" },
    });
  }

  async getRecordingDetails(recordingId: string) {
    return prisma.roomRecording.findUnique({
      where: { id: recordingId },
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

  async archiveRecording(recordingId: string) {
    return prisma.roomRecording.update({
      where: { id: recordingId },
      data: { isArchived: true },
    });
  }

  async unarchiveRecording(recordingId: string) {
    return prisma.roomRecording.update({
      where: { id: recordingId },
      data: { isArchived: false },
    });
  }

  async deleteRecording(recordingId: string) {
    return prisma.roomRecording.delete({
      where: { id: recordingId },
    });
  }

  async makeRecordingPublic(recordingId: string) {
    return prisma.roomRecording.update({
      where: { id: recordingId },
      data: { isPublic: true },
    });
  }

  async makeRecordingPrivate(recordingId: string) {
    return prisma.roomRecording.update({
      where: { id: recordingId },
      data: { isPublic: false },
    });
  }

  async getRoomRecordingStats(roomId: string) {
    const recordings = await prisma.roomRecording.findMany({
      where: { roomId },
    });

    const totalRecordings = recordings.length;
    const totalDuration = recordings.reduce((sum, r) => sum + r.duration, 0);
    const totalFileSize = recordings.reduce((sum, r) => sum + r.fileSize, 0);
    const averageDuration = totalRecordings > 0 ? totalDuration / totalRecordings : 0;

    return {
      totalRecordings,
      totalDuration,
      totalFileSize,
      averageDuration: Math.round(averageDuration),
      publicCount: recordings.filter((r) => r.isPublic).length,
      archivedCount: recordings.filter((r) => r.isArchived).length,
    };
  }

  async cleanupOldRecordings(daysOld = 90) {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - daysOld);

    return prisma.roomRecording.deleteMany({
      where: {
        endedAt: {
          lt: cutoffDate,
        },
        isArchived: false,
      },
    });
  }
}

const service = new RoomRecordingService();

router.post("/rooms/:roomId/recording/start", requireAuth, async (req: Request, res: Response) => {
  try {
    const { roomId } = req.params;
    const userId = (req as any).user?.id;
    const { title, description, recordingUrl } = req.body;

    const recording = await service.startRecording(roomId, userId, {
      title,
      description,
      recordingUrl,
    });

    return res.status(201).json({
      success: true,
      data: recording,
    });
  } catch (error) {
    console.error("startRecording error:", error);
    return res.status(500).json({
      success: false,
      message: "Kayıt başlatılamadı",
    });
  }
});

router.post("/recordings/:recordingId/end", requireAuth, async (req: Request, res: Response) => {
  try {
    const { recordingId } = req.params;
    const { duration, fileSize } = req.body;

    const recording = await service.endRecording(recordingId, duration || 0, fileSize || 0);

    return res.status(200).json({
      success: true,
      data: recording,
    });
  } catch (error) {
    console.error("endRecording error:", error);
    return res.status(500).json({
      success: false,
      message: "Kayıt sonlandırılamadı",
    });
  }
});

router.get("/rooms/:roomId/recordings", async (req: Request, res: Response) => {
  try {
    const { roomId } = req.params;
    const limit = parseInt(req.query.limit as string) || 50;
    const includeArchived = req.query.includeArchived === "true";

    const recordings = await service.getRoomRecordings(roomId, limit, includeArchived);

    return res.status(200).json({
      success: true,
      data: recordings,
    });
  } catch (error) {
    console.error("getRoomRecordings error:", error);
    return res.status(500).json({
      success: false,
      message: "Kayıtlar alınamadı",
    });
  }
});

router.get("/user/recordings", requireAuth, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.id;
    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "Yetkilendirme gerekli",
      });
    }

    const limit = parseInt(req.query.limit as string) || 50;
    const recordings = await service.getUserRecordings(userId, limit);

    return res.status(200).json({
      success: true,
      data: recordings,
    });
  } catch (error) {
    console.error("getUserRecordings error:", error);
    return res.status(500).json({
      success: false,
      message: "Kullanıcı kayıtları alınamadı",
    });
  }
});

router.get("/recordings/:recordingId", async (req: Request, res: Response) => {
  try {
    const { recordingId } = req.params;

    const recording = await service.getRecordingDetails(recordingId);

    if (!recording) {
      return res.status(404).json({
        success: false,
        message: "Kayıt bulunamadı",
      });
    }

    return res.status(200).json({
      success: true,
      data: recording,
    });
  } catch (error) {
    console.error("getRecordingDetails error:", error);
    return res.status(500).json({
      success: false,
      message: "Kayıt alınamadı",
    });
  }
});

router.post("/recordings/:recordingId/archive", requireAuth, async (req: Request, res: Response) => {
  try {
    const { recordingId } = req.params;

    const recording = await service.archiveRecording(recordingId);

    return res.status(200).json({
      success: true,
      data: recording,
    });
  } catch (error) {
    console.error("archiveRecording error:", error);
    return res.status(500).json({
      success: false,
      message: "Kayıt arşivlenemedi",
    });
  }
});

router.post("/recordings/:recordingId/unarchive", requireAuth, async (req: Request, res: Response) => {
  try {
    const { recordingId } = req.params;

    const recording = await service.unarchiveRecording(recordingId);

    return res.status(200).json({
      success: true,
      data: recording,
    });
  } catch (error) {
    console.error("unarchiveRecording error:", error);
    return res.status(500).json({
      success: false,
      message: "Kayıt arşiv çıkarılamadı",
    });
  }
});

router.delete("/recordings/:recordingId", requireAuth, async (req: Request, res: Response) => {
  try {
    const { recordingId } = req.params;

    await service.deleteRecording(recordingId);

    return res.status(200).json({
      success: true,
      message: "Kayıt silindi",
    });
  } catch (error) {
    console.error("deleteRecording error:", error);
    return res.status(500).json({
      success: false,
      message: "Kayıt silinemedi",
    });
  }
});

router.post("/recordings/:recordingId/make-public", requireAuth, async (req: Request, res: Response) => {
  try {
    const { recordingId } = req.params;

    const recording = await service.makeRecordingPublic(recordingId);

    return res.status(200).json({
      success: true,
      data: recording,
    });
  } catch (error) {
    console.error("makeRecordingPublic error:", error);
    return res.status(500).json({
      success: false,
      message: "Kayıt herkese açılamadı",
    });
  }
});

router.post("/recordings/:recordingId/make-private", requireAuth, async (req: Request, res: Response) => {
  try {
    const { recordingId } = req.params;

    const recording = await service.makeRecordingPrivate(recordingId);

    return res.status(200).json({
      success: true,
      data: recording,
    });
  } catch (error) {
    console.error("makeRecordingPrivate error:", error);
    return res.status(500).json({
      success: false,
      message: "Kayıt gizlilenemedi",
    });
  }
});

router.get("/rooms/:roomId/recordings/stats", async (req: Request, res: Response) => {
  try {
    const { roomId } = req.params;

    const stats = await service.getRoomRecordingStats(roomId);

    return res.status(200).json({
      success: true,
      data: stats,
    });
  } catch (error) {
    console.error("getRoomRecordingStats error:", error);
    return res.status(500).json({
      success: false,
      message: "Kayıt istatistikleri alınamadı",
    });
  }
});

export const roomRecordingRouter = router;
