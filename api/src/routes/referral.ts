import { Router } from "express";
import { z } from "zod";
import { prisma } from "../lib/prisma";
import { requireAuth } from "../middleware/requireAuth";
import { requireStaff } from "../middleware/requireStaff";
import { jsonError } from "../lib/jsonError";
import { ok } from "../lib/response";
import {
  ensureUserReferralCode,
  getReferralSettings,
  getReferralStatsForUser,
  reverseReferralCommission,
  updateReferralSettings,
} from "../lib/referralCommissionService";

export const referralRouter = Router();

/** GET /api/referral/me */
referralRouter.get("/referral/me", requireAuth, async (req, res) => {
  const stats = await getReferralStatsForUser(req.userId!);
  return res.status(200).json(stats);
});

/** GET /api/referral — geriye dönük uyumluluk */
referralRouter.get("/referral", requireAuth, async (req, res) => {
  const stats = await getReferralStatsForUser(req.userId!);
  return res.status(200).json({
    referralCode: stats.referralCode,
    referralLink: stats.shareUrl,
    referralUrl: stats.shareUrl,
    shareUrl: stats.shareUrl,
    headline: stats.headline,
    rewardHint: stats.rewardHint,
    inviteCount: stats.invitedCount,
    invitedCount: stats.invitedCount,
    activeReferralCount: stats.activeReferralCount,
    referralCreditsEarned: stats.totalEarnings,
    totalEarnings: stats.totalEarnings,
  });
});

/** GET /api/referral/stats */
referralRouter.get("/referral/stats", requireAuth, async (req, res) => {
  const stats = await getReferralStatsForUser(req.userId!);
  return ok(res, stats);
});

/** GET /api/referral/users */
referralRouter.get("/referral/users", requireAuth, async (req, res) => {
  const userId = req.userId!;
  const rows = await prisma.user.findMany({
    where: { referredByUserId: userId },
    select: {
      id: true,
      username: true,
      displayName: true,
      avatarUrl: true,
      referralJoinedAt: true,
      referralStatus: true,
      createdAt: true,
    },
    orderBy: { referralJoinedAt: "desc" },
    take: 100,
  });

  const enriched = await Promise.all(
    rows.map(async (u) => {
      const volume = await prisma.referralCommissionLedger.aggregate({
        where: { referredUserId: u.id, referrerUserId: userId },
        _sum: { grossJeton: true, referralCommission: true },
      });
      return {
        userId: u.id,
        username: u.username,
        displayName: u.displayName,
        avatarUrl: u.avatarUrl,
        joinedAt: (u.referralJoinedAt ?? u.createdAt).toISOString(),
        status: u.referralStatus,
        eligibleJetonVolume: volume._sum.grossJeton ?? 0,
        referralEarnings: volume._sum.referralCommission ?? 0,
      };
    }),
  );

  return ok(res, { referrals: enriched });
});

/** GET /api/referral/earnings */
referralRouter.get("/referral/earnings", requireAuth, async (req, res) => {
  const stats = await getReferralStatsForUser(req.userId!);
  return ok(res, {
    total: stats.totalEarnings,
    thisMonth: stats.monthEarnings,
    pending: stats.pendingEarnings,
    available: stats.availableEarnings,
    reversed: stats.reversedEarnings,
    capped: stats.cappedEarnings,
    lifetime: stats.lifetimeEarnings,
    monthlyLimit: stats.monthlyLimit,
    lifetimeLimit: stats.lifetimeLimit,
  });
});

/** GET /api/referral/ledger */
referralRouter.get("/referral/ledger", requireAuth, async (req, res) => {
  const limit = Math.min(100, Math.max(1, Number(req.query.limit ?? 50)));
  const rows = await prisma.referralCommissionLedger.findMany({
    where: { referrerUserId: req.userId! },
    orderBy: { createdAt: "desc" },
    take: limit,
  });
  return ok(res, {
    items: rows.map((r) => ({
      id: r.id,
      referredUserId: r.referredUserId,
      sourceType: r.sourceType,
      sourceId: r.sourceId,
      grossJeton: r.grossJeton,
      beneficiaryShare: r.beneficiaryShare,
      referralCommission: r.referralCommission,
      status: r.status,
      cappedAmount: r.cappedAmount,
      createdAt: r.createdAt.toISOString(),
      availableAt: r.availableAt?.toISOString() ?? null,
    })),
  });
});

/** GET /api/referral/invite-link */
referralRouter.get("/referral/invite-link", requireAuth, async (req, res) => {
  const code = await ensureUserReferralCode(req.userId!);
  const origin = (process.env.PUBLIC_SITE_URL ?? "https://canlifal.com").replace(
    /\/$/,
    "",
  );
  const link = `${origin}/davet?ref=${code}`;
  return ok(res, { code, link, shareUrl: link });
});

/** GET /api/referral/settings — kullanıcıya gösterilebilir oranlar */
referralRouter.get("/referral/settings", requireAuth, async (_req, res) => {
  const s = await getReferralSettings();
  return ok(res, {
    livePlatformCommissionRate: s.livePlatformCommissionRate,
    voiceRoomPlatformCommissionRate: s.voiceRoomPlatformCommissionRate,
    falPlatformCommissionRate: s.falPlatformCommissionRate,
    otherPlatformCommissionRate: s.otherPlatformCommissionRate,
    referralCommissionRate: s.referralCommissionRate,
    normalReferralMonthlyCap: s.normalReferralMonthlyCap,
    foundingUserReferralMonthlyCap: s.foundingUserReferralMonthlyCap,
    lifetimeReferralCap: s.lifetimeReferralCap,
    pendingHours: s.pendingHours,
  });
});

/** GET /api/referral/validate?code= */
referralRouter.get("/referral/validate", async (req, res) => {
  const code = String(req.query.code ?? "").trim().toUpperCase();
  if (!code) return jsonError(res, 400, "Kod gerekli");
  const user = await prisma.user.findFirst({
    where: { referralCode: code },
    select: { id: true, username: true, displayName: true },
  });
  if (!user) {
    return res.status(200).json({ valid: false });
  }
  return res.status(200).json({
    valid: true,
    referrer: {
      id: user.id,
      username: user.username,
      displayName: user.displayName,
    },
  });
});

const settingsPatchSchema = z.object({
  livePlatformCommissionRate: z.number().int().min(0).max(100).optional(),
  voiceRoomPlatformCommissionRate: z.number().int().min(0).max(100).optional(),
  falPlatformCommissionRate: z.number().int().min(0).max(100).optional(),
  otherPlatformCommissionRate: z.number().int().min(0).max(100).optional(),
  referralCommissionRate: z.number().int().min(0).max(100).optional(),
  normalReferralMonthlyCap: z.number().int().min(0).optional(),
  foundingUserReferralMonthlyCap: z.number().int().min(0).optional(),
  lifetimeReferralCap: z.number().int().min(0).optional(),
  foundingUserLimit: z.number().int().min(0).optional(),
  foundingUserEnabled: z.boolean().optional(),
  pendingHours: z.number().int().min(0).optional(),
  fraudHoldThreshold: z.number().int().min(0).max(100).optional(),
  fraudBlockThreshold: z.number().int().min(0).max(100).optional(),
  fraudReviewThreshold: z.number().int().min(0).max(100).optional(),
});

/** GET /api/admin/referral/settings */
referralRouter.get(
  "/admin/referral/settings",
  requireAuth,
  requireStaff,
  async (_req, res) => {
    const s = await getReferralSettings();
    return ok(res, s);
  },
);

/** PUT /api/admin/referral/settings */
referralRouter.put(
  "/admin/referral/settings",
  requireAuth,
  requireStaff,
  async (req, res) => {
    const parsed = settingsPatchSchema.safeParse(req.body);
    if (!parsed.success) {
      return jsonError(res, 400, "Geçersiz ayarlar");
    }
    const updated = await updateReferralSettings(parsed.data);
    return ok(res, updated);
  },
);

/** GET /api/admin/referral/ledger */
referralRouter.get(
  "/admin/referral/ledger",
  requireAuth,
  requireStaff,
  async (req, res) => {
    const limit = Math.min(200, Math.max(1, Number(req.query.limit ?? 100)));
    const status = req.query.status ? String(req.query.status) : undefined;
    const rows = await prisma.referralCommissionLedger.findMany({
      where: status ? { status } : undefined,
      orderBy: { createdAt: "desc" },
      take: limit,
    });
    return ok(res, { items: rows });
  },
);

/** GET /api/admin/referral/users */
referralRouter.get(
  "/admin/referral/users",
  requireAuth,
  requireStaff,
  async (req, res) => {
    const limit = Math.min(200, Math.max(1, Number(req.query.limit ?? 50)));
    const grouped = await prisma.user.groupBy({
      by: ["referredByUserId"],
      where: { referredByUserId: { not: null } },
      _count: { id: true },
      orderBy: { _count: { id: "desc" } },
      take: limit,
    });
    return ok(res, { referrers: grouped });
  },
);

/** GET /api/admin/referral/fraud */
referralRouter.get(
  "/admin/referral/fraud",
  requireAuth,
  requireStaff,
  async (req, res) => {
    const limit = Math.min(100, Math.max(1, Number(req.query.limit ?? 50)));
    const rows = await prisma.referralCommissionLedger.findMany({
      where: { status: { in: ["FRAUD_HOLD", "CANCELLED"] } },
      orderBy: { fraudScore: "desc" },
      take: limit,
    });
    return ok(res, { items: rows });
  },
);

/** GET /api/admin/referral/dashboard */
referralRouter.get(
  "/admin/referral/dashboard",
  requireAuth,
  requireStaff,
  async (_req, res) => {
    const monthStart = new Date();
    monthStart.setDate(1);
    monthStart.setHours(0, 0, 0, 0);

    const [
      totalReferrers,
      totalReferred,
      totals,
      monthTotals,
      pending,
      paid,
      reversed,
      fraudHold,
    ] = await Promise.all([
      prisma.user.count({
        where: { referrals: { some: {} } },
      }),
      prisma.user.count({ where: { referredByUserId: { not: null } } }),
      prisma.referralCommissionLedger.aggregate({
        _sum: { referralCommission: true, grossJeton: true, platformNet: true },
      }),
      prisma.referralCommissionLedger.aggregate({
        where: { createdAt: { gte: monthStart } },
        _sum: { referralCommission: true },
      }),
      prisma.referralCommissionLedger.aggregate({
        where: { status: { in: ["PENDING", "FRAUD_HOLD"] } },
        _sum: { referralCommission: true },
      }),
      prisma.referralCommissionLedger.aggregate({
        where: { status: "PAID" },
        _sum: { referralCommission: true },
      }),
      prisma.referralCommissionLedger.aggregate({
        where: { status: "REVERSED" },
        _sum: { referralCommission: true },
      }),
      prisma.referralCommissionLedger.count({
        where: { status: "FRAUD_HOLD" },
      }),
    ]);

    return ok(res, {
      totalReferrers,
      totalReferredUsers: totalReferred,
      totalReferralJeton: totals._sum.referralCommission ?? 0,
      monthReferralJeton: monthTotals._sum.referralCommission ?? 0,
      pendingReferralJeton: pending._sum.referralCommission ?? 0,
      paidReferralJeton: paid._sum.referralCommission ?? 0,
      reversedReferralJeton: reversed._sum.referralCommission ?? 0,
      fraudHoldCount: fraudHold,
      platformReferralCost: totals._sum.referralCommission ?? 0,
      platformNetJeton: totals._sum.platformNet ?? 0,
      grossJetonVolume: totals._sum.grossJeton ?? 0,
    });
  },
);

const reverseSchema = z.object({
  sourceId: z.string().min(1),
  reason: z.string().min(1).max(500),
});

/** POST /api/admin/referral/reverse */
referralRouter.post(
  "/admin/referral/reverse",
  requireAuth,
  requireStaff,
  async (req, res) => {
    const parsed = reverseSchema.safeParse(req.body);
    if (!parsed.success) {
      return jsonError(res, 400, "sourceId ve reason gerekli");
    }
    const count = await reverseReferralCommission(
      parsed.data.sourceId,
      parsed.data.reason,
    );
    return ok(res, { reversed: count });
  },
);
