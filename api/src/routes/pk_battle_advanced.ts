import { Router, Request, Response } from "express";
import { prisma } from "../lib/prisma";
import { requireAuth } from "../middleware/requireAuth";
import { fail, success } from "../lib/response";

const router = Router();

class PkBattleRewardService {
  async calculateBattleRewards(
    battleId: string,
    winnerViewers: number,
    winnerGifts: number,
    loserViewers: number,
    loserGifts: number
  ) {
    const baseReward = 1000;
    const viewerMultiplier = 0.1;
    const giftMultiplier = 0.5;

    const winnerReward = Math.floor(
      baseReward + winnerViewers * viewerMultiplier + winnerGifts * giftMultiplier
    );
    const loserConsolation = Math.floor(baseReward * 0.3);

    return {
      winnerTokens: winnerReward,
      winnerCfc: Math.floor(winnerReward * 0.2),
      loserTokens: loserConsolation,
    };
  }

  async createBattleReward(
    battleId: string,
    winnerId: string,
    loserId: string,
    metrics: {
      winnerViewers: number;
      winnerGifts: number;
      loserViewers: number;
      loserGifts: number;
    }
  ) {
    const rewards = await this.calculateBattleRewards(
      battleId,
      metrics.winnerViewers,
      metrics.winnerGifts,
      metrics.loserViewers,
      metrics.loserGifts
    );

    return prisma.pkBattleReward.create({
      data: {
        battleId,
        winnerRewardTokens: rewards.winnerTokens,
        winnerRewardCfc: rewards.winnerCfc,
        loserConsolationTokens: rewards.loserTokens,
        totalViewersCost: metrics.winnerViewers + metrics.loserViewers,
        totalGiftsCost: metrics.winnerGifts + metrics.loserGifts,
      },
    });
  }

  async distributeBattleRewards(battleId: string, winnerId: string, loserId: string) {
    const reward = await prisma.pkBattleReward.findUnique({
      where: { battleId },
    });

    if (!reward || reward.distributedAt) {
      return null;
    }

    await prisma.user.update({
      where: { id: winnerId },
      data: {
        coins: { increment: reward.winnerRewardTokens },
        cfcBalance: { increment: reward.winnerRewardCfc },
      },
    });

    await prisma.user.update({
      where: { id: loserId },
      data: {
        coins: { increment: reward.loserConsolationTokens },
      },
    });

    return prisma.pkBattleReward.update({
      where: { battleId },
      data: { distributedAt: new Date() },
    });
  }

  async getPendingRewards(battleId: string) {
    return prisma.pkBattleReward.findUnique({
      where: { battleId },
    });
  }
}

class PkBattleEffectService {
  async createBattleEffect(
    battleId: string,
    winnerId: string,
    loserId: string,
    effectType: string,
    intensity: "low" | "normal" | "high" = "normal"
  ) {
    const durations: Record<string, number> = {
      sparkles: 3000,
      explosion: 5000,
      confetti: 4000,
      lightning: 2000,
      water: 3500,
    };

    const particleCounts: Record<string, number> = {
      sparkles: 50,
      explosion: 200,
      confetti: 150,
      lightning: 30,
      water: 80,
    };

    const intensityMultipliers: Record<string, number> = {
      low: 0.5,
      normal: 1.0,
      high: 2.0,
    };

    const baseParticles = particleCounts[effectType] || 100;
    const multiplier = intensityMultipliers[intensity] || 1.0;

    return prisma.pkBattleEffect.create({
      data: {
        battleId,
        winnerId,
        loserId,
        effectType,
        intensity,
        durationSeconds: Math.floor((durations[effectType] || 3000) / 1000),
        particleCount: Math.floor(baseParticles * multiplier),
        soundEnabled: true,
      },
    });
  }

  async getBattleEffects(battleId: string) {
    return prisma.pkBattleEffect.findMany({
      where: { battleId },
      orderBy: { createdAt: "desc" },
    });
  }

  async triggerEffect(effectId: string) {
    const effect = await prisma.pkBattleEffect.findUnique({
      where: { id: effectId },
    });

    if (!effect) return null;

    return {
      battleId: effect.battleId,
      winner: effect.winnerId,
      loser: effect.loserId,
      effect: {
        type: effect.effectType,
        intensity: effect.intensity,
        duration: effect.durationSeconds,
        particles: effect.particleCount,
        sound: effect.soundEnabled,
      },
    };
  }
}

class PkBattleSponsorService {
  async createSponsorship(
    battleId: string,
    sponsorId: string,
    sponsoredTeamId: string,
    amount: number,
    message?: string
  ) {
    return prisma.pkBattleSponsor.create({
      data: {
        battleId,
        sponsorId,
        sponsoredTeamId,
        sponsorshipAmount: amount,
        sponsorshipMessage: message,
        rewardShare: 0.1,
      },
    });
  }

  async getBattleSponsors(battleId: string) {
    return prisma.pkBattleSponsor.findMany({
      where: { battleId },
      include: {
        sponsor: {
          select: {
            id: true,
            displayName: true,
            avatarUrl: true,
          },
        },
      },
      orderBy: { sponsorshipAmount: "desc" },
    });
  }

  async calculateSponsorRewards(battleId: string, totalPrizePool: number) {
    const sponsors = await prisma.pkBattleSponsor.findMany({
      where: { battleId },
    });

    return sponsors.map((s) => ({
      sponsorId: s.sponsorId,
      sponsorshipAmount: s.sponsorshipAmount,
      rewardShare: s.rewardShare,
      estimatedReward: Math.floor(totalPrizePool * s.rewardShare),
    }));
  }

  async distributeSponsorRewards(battleId: string, totalPrizePool: number) {
    const rewards = await this.calculateSponsorRewards(battleId, totalPrizePool);

    for (const reward of rewards) {
      await prisma.user.update({
        where: { id: reward.sponsorId },
        data: {
          coins: { increment: reward.estimatedReward },
        },
      });
    }

    return rewards;
  }
}

const rewardService = new PkBattleRewardService();
const effectService = new PkBattleEffectService();
const sponsorService = new PkBattleSponsorService();

router.post(
  "/pk-battles/:battleId/rewards/calculate",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { battleId } = req.params;
      const { winnerViewers, winnerGifts, loserViewers, loserGifts } = req.body;

      if (
        winnerViewers === undefined ||
        winnerGifts === undefined ||
        loserViewers === undefined ||
        loserGifts === undefined
      ) {
        return fail(res, 400, "VALIDATION_ERROR", "Gerekli metrikler eksik");
      }

      const rewards = await rewardService.calculateBattleRewards(
        battleId,
        winnerViewers,
        winnerGifts,
        loserViewers,
        loserGifts
      );

      return success(res, 200, rewards, "Ödüller hesaplandı");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Ödüller hesaplanamadı");
    }
  }
);

router.post(
  "/pk-battles/:battleId/rewards",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { battleId } = req.params;
      const { winnerId, loserId, winnerViewers, winnerGifts, loserViewers, loserGifts } = req.body;

      if (!winnerId || !loserId) {
        return fail(res, 400, "VALIDATION_ERROR", "Kazanan ve kaybeden gerekli");
      }

      const reward = await rewardService.createBattleReward(
        battleId,
        winnerId,
        loserId,
        { winnerViewers, winnerGifts, loserViewers, loserGifts }
      );

      return success(res, 201, reward, "Ödüller oluşturuldu");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Ödüller oluşturulamadı");
    }
  }
);

router.post(
  "/pk-battles/:battleId/rewards/distribute",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { battleId } = req.params;
      const { winnerId, loserId } = req.body;

      if (!winnerId || !loserId) {
        return fail(res, 400, "VALIDATION_ERROR", "Kazanan ve kaybeden gerekli");
      }

      const result = await rewardService.distributeBattleRewards(battleId, winnerId, loserId);

      if (!result) {
        return fail(res, 404, "NOT_FOUND", "Ödüller bulunamadı");
      }

      return success(res, 200, result, "Ödüller dağıtıldı");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Ödüller dağıtılamadı");
    }
  }
);

router.post(
  "/pk-battles/:battleId/effects",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { battleId } = req.params;
      const { winnerId, loserId, effectType, intensity } = req.body;

      if (!winnerId || !loserId || !effectType) {
        return fail(res, 400, "VALIDATION_ERROR", "Gerekli alanlar eksik");
      }

      const effect = await effectService.createBattleEffect(
        battleId,
        winnerId,
        loserId,
        effectType,
        intensity || "normal"
      );

      return success(res, 201, effect, "Efekt oluşturuldu");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Efekt oluşturulamadı");
    }
  }
);

router.get(
  "/pk-battles/:battleId/effects",
  async (req: Request, res: Response) => {
    try {
      const { battleId } = req.params;
      const effects = await effectService.getBattleEffects(battleId);

      return success(res, 200, effects, "Efektler getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Efektler getirilemedi");
    }
  }
);

router.post(
  "/pk-battles/:battleId/sponsorships",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const hostId = (req as any).userId;
      const { battleId } = req.params;
      const { sponsoredTeamId, amount, message } = req.body;

      if (!sponsoredTeamId || amount === undefined || amount <= 0) {
        return fail(res, 400, "VALIDATION_ERROR", "Gerekli alanlar eksik");
      }

      const sponsorship = await sponsorService.createSponsorship(
        battleId,
        hostId,
        sponsoredTeamId,
        amount,
        message
      );

      return success(res, 201, sponsorship, "Sponsorluk oluşturuldu");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Sponsorluk oluşturulamadı");
    }
  }
);

router.get(
  "/pk-battles/:battleId/sponsorships",
  async (req: Request, res: Response) => {
    try {
      const { battleId } = req.params;
      const sponsors = await sponsorService.getBattleSponsors(battleId);

      return success(res, 200, sponsors, "Sponsorlar getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Sponsorlar getirilemedi");
    }
  }
);

router.post(
  "/pk-battles/:battleId/sponsorships/distribute-rewards",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { battleId } = req.params;
      const { totalPrizePool } = req.body;

      if (totalPrizePool === undefined || totalPrizePool <= 0) {
        return fail(res, 400, "VALIDATION_ERROR", "Ödül havuzu gerekli");
      }

      const rewards = await sponsorService.distributeSponsorRewards(battleId, totalPrizePool);

      return success(res, 200, rewards, "Sponsor ödülleri dağıtıldı");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Sponsor ödülleri dağıtılamadı");
    }
  }
);

export { router as pkBattleAdvancedRouter };
