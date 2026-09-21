import { Router, Request, Response } from "express";
import { prisma } from "../lib/prisma";
import { requireAuth } from "../middleware/requireAuth";
import { fail, success } from "../lib/response";

const router = Router();

class ChatFilterService {
  async getOrCreateFilter(streamId: string) {
    return prisma.chatFilter.upsert({
      where: { streamId },
      update: {},
      create: { streamId, bannedWords: [], autoModEnabled: true },
    });
  }

  async updateFilter(
    streamId: string,
    data: { bannedWords?: string[]; autoModEnabled?: boolean }
  ) {
    return prisma.chatFilter.update({
      where: { streamId },
      data,
    });
  }

  async addBannedWord(streamId: string, word: string) {
    const filter = await this.getOrCreateFilter(streamId);
    if (!filter.bannedWords.includes(word.toLowerCase())) {
      return prisma.chatFilter.update({
        where: { streamId },
        data: { bannedWords: [...filter.bannedWords, word.toLowerCase()] },
      });
    }
    return filter;
  }

  async removeBannedWord(streamId: string, word: string) {
    const filter = await this.getOrCreateFilter(streamId);
    return prisma.chatFilter.update({
      where: { streamId },
      data: {
        bannedWords: filter.bannedWords.filter((w) => w !== word.toLowerCase()),
      },
    });
  }

  async filterMessage(streamId: string, messageText: string) {
    const filter = await this.getOrCreateFilter(streamId);
    if (!filter.autoModEnabled) return { isBlocked: false, violations: [] };

    const violations: string[] = [];
    const lowerText = messageText.toLowerCase();

    filter.bannedWords.forEach((word) => {
      if (lowerText.includes(word)) {
        violations.push(word);
      }
    });

    const isBlocked = violations.length > 0;
    return { isBlocked, violations };
  }

  async reportMessage(
    streamId: string,
    messageId: string,
    userId: string,
    reportedByUserId: string,
    reason: string
  ) {
    const report = await prisma.reportedStreamMessage.create({
      data: {
        streamId,
        messageId,
        userId,
        reportedByUserId,
        reportReason: reason,
      },
      include: {
        user: { select: { id: true, displayName: true } },
        reportedBy: { select: { id: true, displayName: true } },
      },
    });

    await prisma.chatFilter.update({
      where: { streamId },
      data: { reportedMessagesCount: { increment: 1 } },
    });

    return report;
  }

  async getReportedMessages(streamId: string, limit = 50, offset = 0) {
    const [reports, total] = await Promise.all([
      prisma.reportedStreamMessage.findMany({
        where: { streamId },
        include: {
          user: { select: { id: true, displayName: true, avatarUrl: true } },
          reportedBy: { select: { id: true, displayName: true } },
        },
        orderBy: { createdAt: "desc" },
        take: limit,
        skip: offset,
      }),
      prisma.reportedStreamMessage.count({ where: { streamId } }),
    ]);

    return { reports, total, hasMore: offset + limit < total };
  }

  async rejectReport(reportId: string, rejectionReason: string) {
    return prisma.reportedStreamMessage.update({
      where: { id: reportId },
      data: { isModerationRejected: true, moderationRejectionReason: rejectionReason },
    });
  }
}

const service = new ChatFilterService();

router.get(
  "/video-streams/:streamId/chat-filter",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { streamId } = req.params;
      const filter = await service.getOrCreateFilter(streamId);

      return success(res, 200, filter, "Chat filter ayarları getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Chat filter ayarları getirilemedi");
    }
  }
);

router.patch(
  "/video-streams/:streamId/chat-filter",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { streamId } = req.params;
      const { bannedWords, autoModEnabled } = req.body;

      const filter = await service.updateFilter(streamId, {
        bannedWords,
        autoModEnabled,
      });

      return success(res, 200, filter, "Chat filter ayarları güncellendi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Chat filter ayarları güncellenemedi");
    }
  }
);

router.post(
  "/video-streams/:streamId/chat-filter/banned-word",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { streamId } = req.params;
      const { word } = req.body;

      if (!word) {
        return fail(res, 400, "VALIDATION_ERROR", "word gerekli");
      }

      const filter = await service.addBannedWord(streamId, word);

      return success(res, 201, filter, "Yasaklı kelime eklendi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Yasaklı kelime eklenemedi");
    }
  }
);

router.delete(
  "/video-streams/:streamId/chat-filter/banned-word/:word",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { streamId, word } = req.params;

      const filter = await service.removeBannedWord(streamId, decodeURIComponent(word));

      return success(res, 200, filter, "Yasaklı kelime silindi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Yasaklı kelime silinemedi");
    }
  }
);

router.post(
  "/video-streams/:streamId/chat-filter/check-message",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { streamId } = req.params;
      const { messageText } = req.body;

      if (!messageText) {
        return fail(res, 400, "VALIDATION_ERROR", "messageText gerekli");
      }

      const result = await service.filterMessage(streamId, messageText);

      return success(res, 200, result, "Mesaj kontrol edildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Mesaj kontrol edilemedi");
    }
  }
);

router.post(
  "/video-streams/:streamId/chat-filter/report-message",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { streamId } = req.params;
      const { messageId, userId, reason } = req.body;
      const reportedByUserId = (req as any).userId;

      if (!messageId || !userId || !reason) {
        return fail(res, 400, "VALIDATION_ERROR", "messageId, userId, reason gerekli");
      }

      const report = await service.reportMessage(
        streamId,
        messageId,
        userId,
        reportedByUserId,
        reason
      );

      return success(res, 201, report, "Mesaj bildirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Mesaj bildirilemedi");
    }
  }
);

router.get(
  "/video-streams/:streamId/chat-filter/reported-messages",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { streamId } = req.params;
      const limit = Math.min(parseInt(req.query.limit as string) || 50, 100);
      const offset = parseInt(req.query.offset as string) || 0;

      const result = await service.getReportedMessages(streamId, limit, offset);

      return success(res, 200, result, "Bildirilen mesajlar getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Bildirilen mesajlar getirilemedi");
    }
  }
);

router.patch(
  "/video-streams/:streamId/chat-filter/report/:reportId/reject",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { reportId } = req.params;
      const { rejectionReason } = req.body;

      const report = await service.rejectReport(
        reportId,
        rejectionReason || "İnceleme sonucu reddedildi"
      );

      return success(res, 200, report, "Rapor reddedildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Rapor reddedilemedi");
    }
  }
);

export { router as streamChatFilterRouter };
