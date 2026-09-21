import { Router, Request, Response } from "express";
import { prisma } from "../lib/prisma";
import { requireAuth } from "../middleware/requireAuth";
import { fail, success } from "../lib/response";

const router = Router();

class HostBroadcasterTierService {
  async getOrCreateTier(hostId: string) {
    return prisma.hostBroadcasterTier.upsert({
      where: { hostId },
      update: {},
      create: { hostId },
    });
  }

  async calculateTier(totalStreamHours: number, totalFollowers: number, totalEarnings: number) {
    if (totalStreamHours >= 500 && totalFollowers >= 10000 && totalEarnings >= 50000) {
      return "platinum";
    }
    if (totalStreamHours >= 300 && totalFollowers >= 5000 && totalEarnings >= 25000) {
      return "gold";
    }
    if (totalStreamHours >= 100 && totalFollowers >= 1000 && totalEarnings >= 5000) {
      return "silver";
    }
    if (totalStreamHours >= 10 && totalFollowers >= 100) {
      return "bronze";
    }
    return "bronze";
  }

  async updateTierStats(
    hostId: string,
    streamHours: number,
    followers: number,
    earnings: number
  ) {
    const tier = await prisma.hostBroadcasterTier.findUnique({
      where: { hostId },
    });

    if (!tier) {
      return null;
    }

    const newTier = await this.calculateTier(
      tier.totalStreamHours + streamHours,
      tier.totalFollowers + followers,
      tier.totalEarnings + earnings
    );

    const tierChanged = newTier !== tier.tier;

    const updated = await prisma.hostBroadcasterTier.update({
      where: { hostId },
      data: {
        totalStreamHours: { increment: streamHours },
        totalFollowers: { increment: followers },
        totalEarnings: { increment: earnings },
        tier: newTier,
        upgradedAt: tierChanged ? new Date() : tier.upgradedAt,
      },
    });

    return { tier: updated, tierChanged };
  }

  async getTierBenefits(tier: string): Promise<string[]> {
    const benefits: Record<string, string[]> = {
      bronze: [
        "Basic profile badge",
        "Access to 5% discount on gifts",
        "Monthly stats report",
      ],
      silver: [
        "Exclusive silver badge",
        "10% discount on gifts",
        "Weekly detailed analytics",
        "Priority customer support",
        "Custom profile color",
      ],
      gold: [
        "Exclusive gold badge",
        "15% discount on gifts",
        "Daily detailed analytics",
        "24/7 priority support",
        "Custom profile color",
        "Exclusive gold frame on streams",
        "Early access to new features",
      ],
      platinum: [
        "Platinum crown badge",
        "25% discount on gifts",
        "Real-time analytics dashboard",
        "Dedicated account manager",
        "Custom branding options",
        "Platinum frame + glow effect",
        "Exclusive beta features",
        "Custom emotes",
        "Priority placement on trending",
      ],
    };

    return benefits[tier] || benefits.bronze;
  }

  async getUserTier(hostId: string) {
    const tier = await prisma.hostBroadcasterTier.findUnique({
      where: { hostId },
    });

    if (!tier) {
      return null;
    }

    const benefits = await this.getTierBenefits(tier.tier);

    return {
      ...tier,
      benefits,
    };
  }

  async getTierLeaderboard(tier: string, limit: number = 10) {
    return prisma.hostBroadcasterTier.findMany({
      where: { tier },
      orderBy: { totalEarnings: "desc" },
      take: limit,
    });
  }

  async getAllTierLeaderboard(limit: number = 10) {
    return prisma.hostBroadcasterTier.findMany({
      orderBy: { totalEarnings: "desc" },
      take: limit,
    });
  }
}

class HostAchievementBadgeService {
  private badgeDefinitions: Record<
    string,
    { name: string; icon: string; color: string; description: string }
  > = {
    marathon: {
      name: "Marathon Runner",
      icon: "🏃",
      color: "#FF6B6B",
      description: "100+ hours of streaming",
    },
    gifter_magnet: {
      name: "Gifter Magnet",
      icon: "🎁",
      color: "#4ECDC4",
      description: "Received 10,000+ gift value",
    },
    community_leader: {
      name: "Community Leader",
      icon: "👑",
      color: "#FFD700",
      description: "10,000+ followers",
    },
    viral_star: {
      name: "Viral Star",
      icon: "⭐",
      color: "#FF69B4",
      description: "Featured on trending 5+ times",
    },
    early_adopter: {
      name: "Early Adopter",
      icon: "🚀",
      color: "#9B59B6",
      description: "Streaming since the beginning",
    },
    consistency_king: {
      name: "Consistency King",
      icon: "📅",
      color: "#3498DB",
      description: "30-day streaming streak",
    },
    charity_hero: {
      name: "Charity Hero",
      icon: "❤️",
      color: "#E74C3C",
      description: "Donated 50,000+ tokens to charity",
    },
    social_butterfly: {
      name: "Social Butterfly",
      icon: "🦋",
      color: "#F39C12",
      description: "50,000+ total interactions",
    },
  };

  async unlockBadge(hostId: string, badgeType: string) {
    const definition = this.badgeDefinitions[badgeType];
    if (!definition) {
      return null;
    }

    const existing = await prisma.hostAchievementBadge.findUnique({
      where: {
        hostId_badgeType: { hostId, badgeType },
      },
    });

    if (existing) {
      return existing;
    }

    return prisma.hostAchievementBadge.create({
      data: {
        hostId,
        badgeType,
        badgeName: definition.name,
        badgeIcon: definition.icon,
        badgeColor: definition.color,
        description: definition.description,
      },
    });
  }

  async getHostBadges(hostId: string) {
    return prisma.hostAchievementBadge.findMany({
      where: { hostId },
      orderBy: { unlockedAt: "desc" },
    });
  }

  async checkBadgeEligibility(
    hostId: string,
    streamHours: number,
    followers: number,
    giftValue: number,
    trendingCount: number,
    interactionCount: number
  ) {
    const unlockedBadges = await this.getHostBadges(hostId);
    const unlockedTypes = new Set(unlockedBadges.map((b) => b.badgeType));

    const eligibleBadges: string[] = [];

    if (streamHours >= 100 && !unlockedTypes.has("marathon")) {
      eligibleBadges.push("marathon");
    }
    if (giftValue >= 10000 && !unlockedTypes.has("gifter_magnet")) {
      eligibleBadges.push("gifter_magnet");
    }
    if (followers >= 10000 && !unlockedTypes.has("community_leader")) {
      eligibleBadges.push("community_leader");
    }
    if (trendingCount >= 5 && !unlockedTypes.has("viral_star")) {
      eligibleBadges.push("viral_star");
    }
    if (interactionCount >= 50000 && !unlockedTypes.has("social_butterfly")) {
      eligibleBadges.push("social_butterfly");
    }

    return eligibleBadges;
  }

  async getBadgeDefinitions() {
    return this.badgeDefinitions;
  }
}

const tierService = new HostBroadcasterTierService();
const badgeService = new HostAchievementBadgeService();

router.get(
  "/users/me/broadcaster-tier",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const hostId = (req as any).userId;

      const tier = await tierService.getOrCreateTier(hostId);
      const benefits = await tierService.getTierBenefits(tier.tier);

      return success(res, 200, { ...tier, benefits }, "Tier bilgisi getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Tier bilgisi getirilemedi");
    }
  }
);

router.post(
  "/users/me/broadcaster-tier/update-stats",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const hostId = (req as any).userId;
      const { streamHours, followers, earnings } = req.body;

      if (
        streamHours === undefined ||
        followers === undefined ||
        earnings === undefined
      ) {
        return fail(res, 400, "VALIDATION_ERROR", "Gerekli alanlar eksik");
      }

      const result = await tierService.updateTierStats(
        hostId,
        streamHours,
        followers,
        earnings
      );

      if (!result) {
        return fail(res, 404, "NOT_FOUND", "Tier bulunamadı");
      }

      return success(res, 200, result, "Tier istatistikleri güncellendi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "İstatistikler güncellenemedi");
    }
  }
);

router.get(
  "/users/:userId/broadcaster-tier",
  async (req: Request, res: Response) => {
    try {
      const { userId } = req.params;

      const tier = await tierService.getUserTier(userId);

      if (!tier) {
        return fail(res, 404, "NOT_FOUND", "Tier bulunamadı");
      }

      return success(res, 200, tier, "Tier bilgisi getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Tier bilgisi getirilemedi");
    }
  }
);

router.get(
  "/broadcasters/leaderboard/by-tier/:tier",
  async (req: Request, res: Response) => {
    try {
      const { tier } = req.params;
      const limit = Math.min(parseInt(req.query.limit as string) || 10, 100);

      const leaderboard = await tierService.getTierLeaderboard(tier, limit);

      return success(res, 200, leaderboard, "Tier leaderboard getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Leaderboard getirilemedi");
    }
  }
);

router.get(
  "/broadcasters/leaderboard/all",
  async (req: Request, res: Response) => {
    try {
      const limit = Math.min(parseInt(req.query.limit as string) || 10, 100);

      const leaderboard = await tierService.getAllTierLeaderboard(limit);

      return success(res, 200, leaderboard, "Genel leaderboard getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Leaderboard getirilemedi");
    }
  }
);

router.post(
  "/users/me/badges/unlock",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const hostId = (req as any).userId;
      const { badgeType } = req.body;

      if (!badgeType) {
        return fail(res, 400, "VALIDATION_ERROR", "Badge türü gerekli");
      }

      const badge = await badgeService.unlockBadge(hostId, badgeType);

      if (!badge) {
        return fail(res, 400, "INVALID_BADGE", "Geçersiz badge türü");
      }

      return success(res, 201, badge, "Badge açıldı");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Badge açılamadı");
    }
  }
);

router.get(
  "/users/me/badges",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const hostId = (req as any).userId;

      const badges = await badgeService.getHostBadges(hostId);

      return success(res, 200, badges, "Rozetler getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Rozetler getirilemedi");
    }
  }
);

router.get(
  "/users/:userId/badges",
  async (req: Request, res: Response) => {
    try {
      const { userId } = req.params;

      const badges = await badgeService.getHostBadges(userId);

      return success(res, 200, badges, "Rozetler getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Rozetler getirilemedi");
    }
  }
);

router.post(
  "/users/me/badges/check-eligibility",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const hostId = (req as any).userId;
      const {
        streamHours,
        followers,
        giftValue,
        trendingCount,
        interactionCount,
      } = req.body;

      const eligible = await badgeService.checkBadgeEligibility(
        hostId,
        streamHours || 0,
        followers || 0,
        giftValue || 0,
        trendingCount || 0,
        interactionCount || 0
      );

      return success(res, 200, { eligibleBadges: eligible }, "Uygun rozetler kontrol edildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Kontrol edilemedi");
    }
  }
);

router.get(
  "/badges/definitions",
  async (req: Request, res: Response) => {
    try {
      const definitions = await badgeService.getBadgeDefinitions();

      return success(res, 200, definitions, "Badge tanımları getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Tanımlar getirilemedi");
    }
  }
);

export { router as hostTiersBadgesRouter };
