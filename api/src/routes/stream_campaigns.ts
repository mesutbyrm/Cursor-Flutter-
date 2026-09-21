import { Router, Request, Response } from "express";
import { prisma } from "../lib/prisma";
import { requireAuth } from "../middleware/requireAuth";
import { fail, success } from "../lib/response";

const router = Router();

class StreamCampaignService {
  async createCampaign(
    hostId: string,
    data: {
      campaignType: string;
      title: string;
      description?: string;
      rewardType: string;
      rewardValue: number;
      rewardMultiplier?: number;
      minViewers?: number;
      minDuration?: number;
      targetGiftAmount?: number;
      endsAt?: Date;
    }
  ) {
    return prisma.streamLaunchCampaign.create({
      data: {
        hostId,
        campaignType: data.campaignType,
        title: data.title,
        description: data.description,
        rewardType: data.rewardType,
        rewardValue: data.rewardValue,
        rewardMultiplier: data.rewardMultiplier || 1.0,
        minViewers: data.minViewers || 0,
        minDuration: data.minDuration || 0,
        targetGiftAmount: data.targetGiftAmount || 0,
        startedAt: new Date(),
        endsAt: data.endsAt,
      },
    });
  }

  async activeCampaigns(hostId: string) {
    return prisma.streamLaunchCampaign.findMany({
      where: {
        hostId,
        status: "active",
        endsAt: { gt: new Date() },
      },
      orderBy: { createdAt: "desc" },
    });
  }

  async checkCampaignEligibility(
    hostId: string,
    streamData: { viewers: number; duration: number; gifts: number }
  ) {
    const campaigns = await this.activeCampaigns(hostId);
    const eligible = campaigns.filter((c) => {
      return (
        streamData.viewers >= c.minViewers &&
        streamData.duration >= c.minDuration &&
        streamData.gifts >= c.targetGiftAmount
      );
    });

    return eligible;
  }

  async claimCampaignReward(campaignId: string, streamMetrics: any) {
    const campaign = await prisma.streamLaunchCampaign.findUnique({
      where: { id: campaignId },
    });

    if (!campaign || campaign.status !== "active") {
      return null;
    }

    const rewardAmount = Math.floor(campaign.rewardValue * campaign.rewardMultiplier);

    const updated = await prisma.streamLaunchCampaign.update({
      where: { id: campaignId },
      data: {
        status: "completed",
        claimedRewardAt: new Date(),
      },
    });

    return {
      campaign: updated,
      reward: {
        type: campaign.rewardType,
        amount: rewardAmount,
        multiplier: campaign.rewardMultiplier,
      },
    };
  }

  async getOrCreateDailyBonus(hostId: string) {
    return prisma.dailyStreamBonus.upsert({
      where: { hostId },
      update: {},
      create: { hostId },
    });
  }

  async checkDailyStreakBonus(hostId: string) {
    const bonus = await this.getOrCreateDailyBonus(hostId);
    const today = new Date().toDateString();
    const lastStream = bonus.lastStreamDate?.toDateString();

    if (lastStream === today) {
      return { isEligible: false, reason: "Already streamed today" };
    }

    const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000).toDateString();
    const isConsecutive = lastStream === yesterday;

    const newStreak = isConsecutive ? bonus.streakDays + 1 : 1;
    const multiplier = 1.0 + (newStreak - 1) * 0.1;

    return {
      isEligible: true,
      streakDays: newStreak,
      multiplier,
      bonusAmount: Math.floor(bonus.bonusPerStream * multiplier),
    };
  }

  async claimDailyBonus(hostId: string) {
    const bonus = await this.getOrCreateDailyBonus(hostId);
    const check = await this.checkDailyStreakBonus(hostId);

    if (!check.isEligible) {
      return null;
    }

    const updated = await prisma.dailyStreamBonus.update({
      where: { hostId },
      data: {
        lastStreamDate: new Date(),
        streakDays: check.streakDays,
        streakMultiplier: check.multiplier,
        totalBonusEarned: {
          increment: check.bonusAmount,
        },
      },
    });

    return {
      streakDays: updated.streakDays,
      dailyBonus: check.bonusAmount,
      totalEarned: updated.totalBonusEarned,
      multiplier: updated.streakMultiplier,
    };
  }

  async resetDailyStreakIfExpired(hostId: string) {
    const bonus = await this.getOrCreateDailyBonus(hostId);
    const lastStream = bonus.lastStreamDate;

    if (!lastStream) return bonus;

    const hoursSinceStream =
      (Date.now() - lastStream.getTime()) / (1000 * 60 * 60);

    if (hoursSinceStream > 48) {
      return await prisma.dailyStreamBonus.update({
        where: { hostId },
        data: { streakDays: 0, streakMultiplier: 1.0 },
      });
    }

    return bonus;
  }
}

const service = new StreamCampaignService();

router.post(
  "/video-streams/:streamId/campaign/start",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const hostId = (req as any).userId;
      const {
        campaignType,
        title,
        description,
        rewardType,
        rewardValue,
        rewardMultiplier,
        minViewers,
        minDuration,
        targetGiftAmount,
        endsAt,
      } = req.body;

      if (!campaignType || !title || !rewardType || rewardValue === undefined) {
        return fail(res, 400, "VALIDATION_ERROR", "Gerekli alanlar eksik");
      }

      const campaign = await service.createCampaign(hostId, {
        campaignType,
        title,
        description,
        rewardType,
        rewardValue,
        rewardMultiplier,
        minViewers,
        minDuration,
        targetGiftAmount,
        endsAt: endsAt ? new Date(endsAt) : undefined,
      });

      return success(res, 201, campaign, "Kampanya başlatıldı");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Kampanya başlatılamadı");
    }
  }
);

router.get(
  "/users/me/campaigns/active",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const hostId = (req as any).userId;
      const campaigns = await service.activeCampaigns(hostId);

      return success(res, 200, campaigns, "Aktif kampanyalar getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Aktif kampanyalar getirilemedi");
    }
  }
);

router.post(
  "/video-streams/:streamId/campaign/check-eligibility",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const hostId = (req as any).userId;
      const { viewers, duration, gifts } = req.body;

      const eligible = await service.checkCampaignEligibility(hostId, {
        viewers,
        duration,
        gifts,
      });

      return success(res, 200, eligible, "Uygun kampanyalar kontrol edildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Kampanya uygunluğu kontrol edilemedi");
    }
  }
);

router.post(
  "/video-streams/:streamId/campaign/:campaignId/claim-reward",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { campaignId } = req.params;
      const { streamMetrics } = req.body;

      const result = await service.claimCampaignReward(campaignId, streamMetrics);

      if (!result) {
        return fail(res, 404, "NOT_FOUND", "Kampanya bulunamadı");
      }

      return success(res, 200, result, "Kampanya ödülü talep edildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Kampanya ödülü talep edilemedi");
    }
  }
);

router.get(
  "/users/me/daily-bonus",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const hostId = (req as any).userId;

      const check = await service.checkDailyStreakBonus(hostId);

      return success(res, 200, check, "Günlük bonus durumu kontrol edildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Günlük bonus kontrol edilemedi");
    }
  }
);

router.post(
  "/users/me/daily-bonus/claim",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const hostId = (req as any).userId;

      await service.resetDailyStreakIfExpired(hostId);
      const result = await service.claimDailyBonus(hostId);

      if (!result) {
        return fail(res, 400, "ALREADY_CLAIMED", "Bugün zaten bonus talep ettiniz");
      }

      return success(res, 200, result, "Günlük bonus talep edildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Günlük bonus talep edilemedi");
    }
  }
);

router.get(
  "/users/me/daily-bonus/status",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const hostId = (req as any).userId;

      const bonus = await service.getOrCreateDailyBonus(hostId);
      const check = await service.checkDailyStreakBonus(hostId);

      return success(
        res,
        200,
        { ...bonus, check },
        "Bonus durumu getirildi"
      );
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Bonus durumu getirilemedi");
    }
  }
);

export { router as streamCampaignsRouter };
