import { Router, Request, Response } from "express";
import { prisma } from "../lib/prisma";
import { requireAuth } from "../middleware/requireAuth";
import { fail, success } from "../lib/response";

const router = Router();

class StreamVipService {
  async addVipViewer(
    streamId: string,
    userId: string,
    tier: string,
    privileges: string[],
    expiresAt?: Date
  ) {
    return prisma.streamVipViewer.upsert({
      where: { streamId_userId: { streamId, userId } },
      update: { tier, privileges, expiresAt },
      create: {
        streamId,
        userId,
        tier,
        privileges,
        expiresAt,
      },
      include: {
        user: { select: { id: true, displayName: true, avatarUrl: true } },
      },
    });
  }

  async removeVipViewer(streamId: string, userId: string) {
    return prisma.streamVipViewer.delete({
      where: { streamId_userId: { streamId, userId } },
    });
  }

  async getVipViewers(streamId: string) {
    return prisma.streamVipViewer.findMany({
      where: {
        streamId,
        OR: [{ expiresAt: null }, { expiresAt: { gt: new Date() } }],
      },
      include: {
        user: { select: { id: true, displayName: true, avatarUrl: true } },
      },
      orderBy: { addedAt: "desc" },
    });
  }

  async updateVipPrivileges(
    streamId: string,
    userId: string,
    privileges: string[]
  ) {
    return prisma.streamVipViewer.update({
      where: { streamId_userId: { streamId, userId } },
      data: { privileges },
      include: {
        user: { select: { id: true, displayName: true } },
      },
    });
  }

  async checkVipStatus(streamId: string, userId: string) {
    const vip = await prisma.streamVipViewer.findUnique({
      where: { streamId_userId: { streamId, userId } },
    });

    if (!vip) return null;

    if (vip.expiresAt && vip.expiresAt < new Date()) {
      await this.removeVipViewer(streamId, userId);
      return null;
    }

    return vip;
  }

  async getVipStats(streamId: string) {
    const vips = await prisma.streamVipViewer.groupBy({
      by: ["tier"],
      where: {
        streamId,
        OR: [{ expiresAt: null }, { expiresAt: { gt: new Date() } }],
      },
      _count: true,
    });

    const result = {} as Record<string, number>;
    vips.forEach((v) => {
      result[v.tier] = v._count;
    });

    return {
      totalVips: Object.values(result).reduce((a, b) => a + b, 0),
      byTier: result,
    };
  }

  async extendVipMembership(
    streamId: string,
    userId: string,
    daysToAdd: number
  ) {
    const vip = await prisma.streamVipViewer.findUnique({
      where: { streamId_userId: { streamId, userId } },
    });

    if (!vip) {
      return fail("VIP kullanıcı bulunamadı");
    }

    const newExpiresAt = vip.expiresAt
      ? new Date(vip.expiresAt.getTime() + daysToAdd * 24 * 60 * 60 * 1000)
      : new Date(Date.now() + daysToAdd * 24 * 60 * 60 * 1000);

    return prisma.streamVipViewer.update({
      where: { streamId_userId: { streamId, userId } },
      data: { expiresAt: newExpiresAt },
      include: {
        user: { select: { id: true, displayName: true } },
      },
    });
  }
}

const service = new StreamVipService();

router.post(
  "/video-streams/:streamId/vip/add",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { streamId } = req.params;
      const { userId, tier, privileges, expiresAt } = req.body;

      if (!userId || !tier) {
        return fail(res, 400, "VALIDATION_ERROR", "userId ve tier gerekli");
      }

      const vip = await service.addVipViewer(
        streamId,
        userId,
        tier,
        privileges || [],
        expiresAt ? new Date(expiresAt) : undefined
      );

      return success(res, 201, vip, "VIP izleyici eklendi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "VIP izleyici eklenemedi");
    }
  }
);

router.delete(
  "/video-streams/:streamId/vip/:userId",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { streamId, userId } = req.params;

      await service.removeVipViewer(streamId, userId);

      return success(res, 200, null, "VIP izleyici kaldırıldı");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "VIP izleyici kaldırılamadı");
    }
  }
);

router.get(
  "/video-streams/:streamId/vip/list",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { streamId } = req.params;

      const vips = await service.getVipViewers(streamId);

      return success(res, 200, vips, "VIP izleyiciler getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "VIP izleyiciler getirilemedi");
    }
  }
);

router.patch(
  "/video-streams/:streamId/vip/:userId/privileges",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { streamId, userId } = req.params;
      const { privileges } = req.body;

      if (!privileges || !Array.isArray(privileges)) {
        return fail(res, 400, "VALIDATION_ERROR", "privileges gerekli ve array olmalı");
      }

      const vip = await service.updateVipPrivileges(streamId, userId, privileges);

      return success(res, 200, vip, "VIP yetkiler güncellendi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "VIP yetkiler güncellenemedi");
    }
  }
);

router.get(
  "/video-streams/:streamId/vip/:userId/status",
  async (req: Request, res: Response) => {
    try {
      const { streamId, userId } = req.params;

      const vip = await service.checkVipStatus(streamId, userId);

      return success(
        res,
        200,
        { isVip: !!vip, vip },
        "VIP durumu kontrol edildi"
      );
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "VIP durumu kontrol edilemedi");
    }
  }
);

router.get(
  "/video-streams/:streamId/vip/stats",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { streamId } = req.params;

      const stats = await service.getVipStats(streamId);

      return success(res, 200, stats, "VIP istatistikleri getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "VIP istatistikleri getirilemedi");
    }
  }
);

router.patch(
  "/video-streams/:streamId/vip/:userId/extend",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { streamId, userId } = req.params;
      const { daysToAdd } = req.body;

      if (!daysToAdd || daysToAdd <= 0) {
        return fail(res, 400, "VALIDATION_ERROR", "daysToAdd gerekli ve pozitif olmalı");
      }

      const vip = await service.extendVipMembership(streamId, userId, daysToAdd);

      return success(res, 200, vip, "VIP üyeliği uzatıldı");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "VIP üyeliği uzatılamadı");
    }
  }
);

export { router as streamVipRouter };
