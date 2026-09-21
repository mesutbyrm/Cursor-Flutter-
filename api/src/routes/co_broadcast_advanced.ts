import { Router, Request, Response } from "express";
import { prisma } from "../lib/prisma";
import { requireAuth } from "../middleware/requireAuth";
import { fail, ok } from "../lib/response";

const router = Router();

class CoBroadcastSessionService {
  async createSession(
    streamId: string,
    hostId: string,
    guestId: string,
    revenueShare: number = 20.0,
    permissionLevel: string = "basic"
  ) {
    const existingSession = await prisma.coBroadcastSession.findUnique({
      where: {
        streamId_guestId: { streamId, guestId },
      },
    });

    if (existingSession) {
      return existingSession;
    }

    return prisma.coBroadcastSession.create({
      data: {
        streamId,
        hostId,
        guestId,
        status: "pending",
        permissionLevel,
        revenueSharePercent: revenueShare,
        startedAt: new Date(),
      },
      include: {
        guest: {
          select: { id: true, displayName: true, avatarUrl: true },
        },
      },
    });
  }

  async acceptSession(sessionId: string) {
    return prisma.coBroadcastSession.update({
      where: { id: sessionId },
      data: { status: "active" },
      include: {
        guest: {
          select: { id: true, displayName: true, avatarUrl: true },
        },
      },
    });
  }

  async rejectSession(sessionId: string) {
    return prisma.coBroadcastSession.update({
      where: { id: sessionId },
      data: { status: "rejected" },
    });
  }

  async endSession(sessionId: string) {
    return prisma.coBroadcastSession.update({
      where: { id: sessionId },
      data: {
        status: "completed",
        endedAt: new Date(),
      },
    });
  }

  async updatePermissions(
    sessionId: string,
    permissionLevel: string
  ) {
    const validPermissions = ["basic", "advanced", "full"];
    if (!validPermissions.includes(permissionLevel)) {
      return null;
    }

    return prisma.coBroadcastSession.update({
      where: { id: sessionId },
      data: { permissionLevel },
    });
  }

  async getActiveSessions(streamId: string) {
    return prisma.coBroadcastSession.findMany({
      where: {
        streamId,
        status: "active",
      },
      include: {
        guest: {
          select: { id: true, displayName: true, avatarUrl: true },
        },
      },
    });
  }

  async getPendingSessions(hostId: string) {
    return prisma.coBroadcastSession.findMany({
      where: {
        hostId,
        status: "pending",
      },
      include: {
        guest: {
          select: { id: true, displayName: true, avatarUrl: true },
        },
      },
      orderBy: { createdAt: "desc" },
    });
  }

  async getGuestInvitations(guestId: string) {
    return prisma.coBroadcastSession.findMany({
      where: { guestId },
      orderBy: { createdAt: "desc" },
    });
  }
}

class CoBroadcastWaitlistService {
  async addToWaitlist(streamId: string, userId: string) {
    const count = await prisma.coBroadcastWaitlist.count({
      where: { streamId },
    });

    return prisma.coBroadcastWaitlist.create({
      data: {
        streamId,
        waitlistUserId: userId,
        position: count + 1,
      },
      include: {
        user: {
          select: { id: true, displayName: true, avatarUrl: true },
        },
      },
    });
  }

  async removeFromWaitlist(waitlistId: string) {
    const removed = await prisma.coBroadcastWaitlist.delete({
      where: { id: waitlistId },
    });

    await this.reorderWaitlist(removed.streamId);
    return removed;
  }

  async getWaitlist(streamId: string) {
    return prisma.coBroadcastWaitlist.findMany({
      where: { streamId, acceptedAt: null },
      include: {
        user: {
          select: { id: true, displayName: true, avatarUrl: true },
        },
      },
      orderBy: { position: "asc" },
    });
  }

  async acceptFromWaitlist(waitlistId: string) {
    return prisma.coBroadcastWaitlist.update({
      where: { id: waitlistId },
      data: { acceptedAt: new Date() },
    });
  }

  async getWaitlistPosition(streamId: string, userId: string) {
    const entry = await prisma.coBroadcastWaitlist.findUnique({
      where: {
        streamId_waitlistUserId: { streamId, waitlistUserId: userId },
      },
    });

    return entry?.position ?? null;
  }

  private async reorderWaitlist(streamId: string) {
    const waitlist = await prisma.coBroadcastWaitlist.findMany({
      where: { streamId },
      orderBy: { position: "asc" },
    });

    for (let i = 0; i < waitlist.length; i++) {
      await prisma.coBroadcastWaitlist.update({
        where: { id: waitlist[i].id },
        data: { position: i + 1 },
      });
    }
  }
}

class CoBroadcastRevenueService {
  async calculateRevenue(
    sessionId: string,
    totalRevenue: number
  ) {
    const session = await prisma.coBroadcastSession.findUnique({
      where: { id: sessionId },
    });

    if (!session) return null;

    const guestEarnings = Math.floor(totalRevenue * (session.revenueSharePercent / 100));
    const hostEarnings = totalRevenue - guestEarnings;

    return {
      totalRevenue,
      guestShare: session.revenueSharePercent,
      guestEarnings,
      hostEarnings,
    };
  }

  async recordRevenue(sessionId: string, amount: number) {
    return prisma.coBroadcastSession.update({
      where: { id: sessionId },
      data: {
        earnedAmount: { increment: amount },
      },
    });
  }

  async distributeRevenue(sessionId: string, totalAmount: number) {
    const revenue = await this.calculateRevenue(sessionId, totalAmount);
    if (!revenue) return null;

    const session = await prisma.coBroadcastSession.findUnique({
      where: { id: sessionId },
    });

    if (!session) return null;

    await prisma.user.update({
      where: { id: session.guestId },
      data: { coins: { increment: revenue.guestEarnings } },
    });

    await prisma.user.update({
      where: { id: session.hostId },
      data: { coins: { increment: revenue.hostEarnings } },
    });

    return revenue;
  }

  async getSessionEarnings(sessionId: string) {
    const session = await prisma.coBroadcastSession.findUnique({
      where: { id: sessionId },
    });

    if (!session) return null;

    return {
      sessionId,
      totalEarned: session.earnedAmount,
      guestShare: session.revenueSharePercent,
      guestEarnings: Math.floor(session.earnedAmount * (session.revenueSharePercent / 100)),
      hostEarnings: Math.floor(session.earnedAmount * (100 - session.revenueSharePercent) / 100),
    };
  }
}

const sessionService = new CoBroadcastSessionService();
const waitlistService = new CoBroadcastWaitlistService();
const revenueService = new CoBroadcastRevenueService();

router.post(
  "/video-streams/:streamId/co-broadcast/invite-guest",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const hostId = (req as any).userId;
      const { streamId } = req.params;
      const { guestId, revenueShare, permissionLevel } = req.body;

      if (!guestId) {
        return fail(res, 400, "VALIDATION_ERROR", "Misafir ID gerekli");
      }

      const session = await sessionService.createSession(
        streamId,
        hostId,
        guestId,
        revenueShare || 20.0,
        permissionLevel || "basic"
      );

      return ok(res, session);
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Davet gönderilemedi");
    }
  }
);

router.post(
  "/video-streams/:streamId/co-broadcast/guest/:sessionId/accept",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { sessionId } = req.params;

      const session = await sessionService.acceptSession(sessionId);

      return ok(res, session);
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Davet kabul edilemedi");
    }
  }
);

router.post(
  "/video-streams/:streamId/co-broadcast/guest/:sessionId/reject",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { sessionId } = req.params;

      await sessionService.rejectSession(sessionId);

      return ok(res, null);
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Davet reddedilemedi");
    }
  }
);

router.post(
  "/video-streams/:streamId/co-broadcast/guest/:sessionId/end",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { sessionId } = req.params;

      const session = await sessionService.endSession(sessionId);

      return ok(res, session);
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Seans sonlandırılamadı");
    }
  }
);

router.post(
  "/video-streams/:streamId/co-broadcast/guest/:sessionId/permissions",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { sessionId } = req.params;
      const { permissionLevel } = req.body;

      if (!permissionLevel) {
        return fail(res, 400, "VALIDATION_ERROR", "Yetki seviyesi gerekli");
      }

      const updated = await sessionService.updatePermissions(sessionId, permissionLevel);

      if (!updated) {
        return fail(res, 400, "INVALID_PERMISSION", "Geçersiz yetki seviyesi");
      }

      return ok(res, updated);
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Yetkiler güncellenemedi");
    }
  }
);

router.get(
  "/video-streams/:streamId/co-broadcast/active",
  async (req: Request, res: Response) => {
    try {
      const { streamId } = req.params;

      const sessions = await sessionService.getActiveSessions(streamId);

      return ok(res, sessions);
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Misafirler getirilemedi");
    }
  }
);

router.get(
  "/users/me/co-broadcast/invitations",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const userId = (req as any).userId;

      const invitations = await sessionService.getGuestInvitations(userId);

      return ok(res, invitations);
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Davetler getirilemedi");
    }
  }
);

router.post(
  "/video-streams/:streamId/co-broadcast/waitlist/add",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const userId = (req as any).userId;
      const { streamId } = req.params;

      const position = await waitlistService.addToWaitlist(streamId, userId);

      return ok(res, position);
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Listeye eklenemedi");
    }
  }
);

router.get(
  "/video-streams/:streamId/co-broadcast/waitlist",
  async (req: Request, res: Response) => {
    try {
      const { streamId } = req.params;

      const waitlist = await waitlistService.getWaitlist(streamId);

      return ok(res, waitlist);
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Liste getirilemedi");
    }
  }
);

router.get(
  "/users/me/co-broadcast/waitlist-position/:streamId",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const userId = (req as any).userId;
      const { streamId } = req.params;

      const position = await waitlistService.getWaitlistPosition(streamId, userId);

      if (position === null) {
        return ok(res, { position: null });
      }

      return ok(res, { position });
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Konum getirilemedi");
    }
  }
);

router.post(
  "/video-streams/:streamId/co-broadcast/distribute-revenue",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { streamId } = req.params;
      const { sessionId, totalAmount } = req.body;

      if (!sessionId || totalAmount === undefined || totalAmount <= 0) {
        return fail(res, 400, "VALIDATION_ERROR", "Gerekli alanlar eksik");
      }

      const distribution = await revenueService.distributeRevenue(sessionId, totalAmount);

      if (!distribution) {
        return fail(res, 404, "NOT_FOUND", "Seans bulunamadı");
      }

      return ok(res, distribution);
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Gelir dağıtılamadı");
    }
  }
);

router.get(
  "/co-broadcast-sessions/:sessionId/earnings",
  async (req: Request, res: Response) => {
    try {
      const { sessionId } = req.params;

      const earnings = await revenueService.getSessionEarnings(sessionId);

      if (!earnings) {
        return fail(res, 404, "NOT_FOUND", "Seans bulunamadı");
      }

      return ok(res, earnings);
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Kazançlar getirilemedi");
    }
  }
);

export { router as coBroadcastAdvancedRouter };
