import { Router, Request, Response } from "express";
import { prisma } from "../lib/prisma";
import { requireAuth } from "../middleware/requireAuth";
import { fail, success } from "../lib/response";

const router = Router();

class LiveStreamMembershipOfferService {
  async createMembershipOffer(
    streamId: string,
    hostId: string,
    membershipType: string,
    basePriceTokens: number,
    discountPercent: number,
    startsAt: Date,
    endsAt?: Date,
    limitPerStream?: number,
    message?: string,
    badge?: string
  ) {
    return prisma.liveStreamMembershipOffer.create({
      data: {
        streamId,
        hostId,
        membershipType,
        basePriceTokens,
        discountPercent,
        discountStartsAt: startsAt,
        discountEndsAt: endsAt,
        limitPerStream,
        offerMessage: message,
        badgeForPurchasers: badge,
      },
    });
  }

  async getActiveOffers(streamId: string) {
    const now = new Date();
    return prisma.liveStreamMembershipOffer.findMany({
      where: {
        streamId,
        discountStartsAt: { lte: now },
        OR: [
          { discountEndsAt: null },
          { discountEndsAt: { gt: now } },
        ],
      },
      orderBy: { createdAt: "desc" },
    });
  }

  async checkOfferAvailability(offerId: string): Promise<boolean> {
    const offer = await prisma.liveStreamMembershipOffer.findUnique({
      where: { id: offerId },
    });

    if (!offer) return false;

    const now = new Date();
    if (offer.discountStartsAt > now || (offer.discountEndsAt && offer.discountEndsAt < now)) {
      return false;
    }

    if (offer.limitPerStream && offer.soldCount >= offer.limitPerStream) {
      return false;
    }

    return true;
  }

  async calculateDiscountedPrice(offer: any): Promise<number> {
    const discountAmount = Math.floor(offer.basePriceTokens * (offer.discountPercent / 100));
    return offer.basePriceTokens - discountAmount;
  }

  async purchaseMembership(
    offerId: string,
    userId: string,
    membershipType: string,
    basePrice: number,
    discountedPrice: number
  ) {
    const offer = await prisma.liveStreamMembershipOffer.findUnique({
      where: { id: offerId },
    });

    if (!offer) return null;

    const isAvailable = await this.checkOfferAvailability(offerId);
    if (!isAvailable) {
      return null;
    }

    await prisma.user.update({
      where: { id: userId },
      data: {
        coins: { decrement: discountedPrice },
        membership: membershipType,
        membershipExpiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      },
    });

    const updated = await prisma.liveStreamMembershipOffer.update({
      where: { id: offerId },
      data: {
        soldCount: { increment: 1 },
      },
    });

    const savedTokens = basePrice - discountedPrice;

    return {
      success: true,
      userId,
      membershipType,
      originalPrice: basePrice,
      discountedPrice,
      savedTokens,
      purchasedAt: new Date(),
      expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
    };
  }

  async getOfferStats(offerId: string) {
    const offer = await prisma.liveStreamMembershipOffer.findUnique({
      where: { id: offerId },
    });

    if (!offer) return null;

    const revenue = offer.basePriceTokens * offer.soldCount;
    const discountCost = Math.floor(
      offer.basePriceTokens * offer.discountPercent * offer.soldCount / 100
    );

    return {
      offerId: offer.id,
      membershipType: offer.membershipType,
      totalSold: offer.soldCount,
      remainingLimit: offer.limitPerStream ? offer.limitPerStream - offer.soldCount : null,
      totalRevenue: revenue,
      discountCost,
      netRevenue: revenue - discountCost,
      averagePrice: Math.floor(revenue / Math.max(1, offer.soldCount)),
    };
  }
}

class LiveStreamTokenPackageService {
  async createTokenPackage(
    streamId: string,
    hostId: string,
    packageName: string,
    tokenAmount: number,
    baseCost: number,
    discountedCost: number,
    bonusTokens?: number,
    bonusMessage?: string
  ) {
    return prisma.liveStreamTokenPackage.create({
      data: {
        streamId,
        hostId,
        packageName,
        tokenAmount,
        baseCost,
        discountedCost,
        bonusTokens: bonusTokens || 0,
        bonusMessage,
      },
    });
  }

  async getPackagesByStream(streamId: string) {
    return prisma.liveStreamTokenPackage.findMany({
      where: { streamId },
      orderBy: { tokenAmount: "asc" },
    });
  }

  async calculatePackageValue(packageId: string) {
    const pkg = await prisma.liveStreamTokenPackage.findUnique({
      where: { id: packageId },
    });

    if (!pkg) return null;

    const discount = pkg.baseCost - pkg.discountedCost;
    const discountPercent = Math.floor((discount / pkg.baseCost) * 100);
    const totalTokens = pkg.tokenAmount + pkg.bonusTokens;
    const costPerToken = Math.floor(pkg.discountedCost / totalTokens);

    return {
      packageId: pkg.id,
      name: pkg.packageName,
      baseTokens: pkg.tokenAmount,
      bonusTokens: pkg.bonusTokens,
      totalTokens,
      baseCost: pkg.baseCost,
      discountedCost: pkg.discountedCost,
      discount,
      discountPercent: `${discountPercent}%`,
      costPerToken,
      bonus: {
        tokens: pkg.bonusTokens,
        message: pkg.bonusMessage,
      },
    };
  }

  async purchaseTokenPackage(packageId: string, userId: string) {
    const pkg = await prisma.liveStreamTokenPackage.findUnique({
      where: { id: packageId },
    });

    if (!pkg) return null;

    const user = await prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user || user.coins < pkg.discountedCost) {
      return null;
    }

    await prisma.user.update({
      where: { id: userId },
      data: {
        coins: { decrement: pkg.discountedCost },
      },
    });

    const purchase = await prisma.streamPurchaseReward.create({
      data: {
        purchaseId: `${packageId}-${userId}-${Date.now()}`,
        userId,
        rewardType: "token_package",
        rewardValue: (pkg.tokenAmount + pkg.bonusTokens).toString(),
      },
    });

    return {
      success: true,
      purchaseId: purchase.id,
      packageName: pkg.packageName,
      tokensReceived: pkg.tokenAmount,
      bonusTokens: pkg.bonusTokens,
      totalTokens: pkg.tokenAmount + pkg.bonusTokens,
      cost: pkg.discountedCost,
      savings: pkg.baseCost - pkg.discountedCost,
      purchasedAt: new Date(),
    };
  }
}

class StreamPurchaseRewardService {
  async getRewardsByUser(userId: string) {
    return prisma.streamPurchaseReward.findMany({
      where: { userId },
      orderBy: { createdAt: "desc" },
    });
  }

  async getTotalRewardValue(userId: string): Promise<number> {
    const rewards = await prisma.streamPurchaseReward.findMany({
      where: { userId },
    });

    return rewards.reduce((total, r) => {
      const value = parseInt(r.rewardValue, 10) || 0;
      return total + value;
    }, 0);
  }

  async claimReward(rewardId: string, userId: string) {
    const reward = await prisma.streamPurchaseReward.findUnique({
      where: { id: rewardId },
    });

    if (!reward || reward.userId !== userId) {
      return null;
    }

    const value = parseInt(reward.rewardValue, 10) || 0;

    await prisma.user.update({
      where: { id: userId },
      data: {
        coins: { increment: value },
      },
    });

    return {
      success: true,
      rewardId,
      rewardType: reward.rewardType,
      value,
      claimedAt: new Date(),
    };
  }

  async giftRewardToHost(rewardId: string, userId: string, hostId: string) {
    const reward = await prisma.streamPurchaseReward.findUnique({
      where: { id: rewardId },
    });

    if (!reward || reward.userId !== userId) {
      return null;
    }

    const value = parseInt(reward.rewardValue, 10) || 0;

    await prisma.user.update({
      where: { id: hostId },
      data: {
        coins: { increment: Math.floor(value * 0.9) },
      },
    });

    return prisma.streamPurchaseReward.update({
      where: { id: rewardId },
      data: {
        giftedToStreamHostId: hostId,
      },
    });
  }
}

const membershipService = new LiveStreamMembershipOfferService();
const tokenService = new LiveStreamTokenPackageService();
const rewardService = new StreamPurchaseRewardService();

router.post(
  "/video-streams/:streamId/membership-offers",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const hostId = (req as any).userId;
      const { streamId } = req.params;
      const {
        membershipType,
        basePriceTokens,
        discountPercent,
        startsAt,
        endsAt,
        limitPerStream,
        message,
        badge,
      } = req.body;

      if (!membershipType || basePriceTokens === undefined || discountPercent === undefined) {
        return fail(res, 400, "VALIDATION_ERROR", "Gerekli alanlar eksik");
      }

      const offer = await membershipService.createMembershipOffer(
        streamId,
        hostId,
        membershipType,
        basePriceTokens,
        discountPercent,
        startsAt ? new Date(startsAt) : new Date(),
        endsAt ? new Date(endsAt) : undefined,
        limitPerStream,
        message,
        badge
      );

      return success(res, 201, offer, "Üyelik teklifi oluşturuldu");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Teklif oluşturulamadı");
    }
  }
);

router.get(
  "/video-streams/:streamId/membership-offers/active",
  async (req: Request, res: Response) => {
    try {
      const { streamId } = req.params;
      const offers = await membershipService.getActiveOffers(streamId);

      return success(res, 200, offers, "Aktif teklifler getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Teklifler getirilemedi");
    }
  }
);

router.post(
  "/membership-offers/:offerId/purchase",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const userId = (req as any).userId;
      const { offerId } = req.params;

      const offer = await prisma.liveStreamMembershipOffer.findUnique({
        where: { id: offerId },
      });

      if (!offer) {
        return fail(res, 404, "NOT_FOUND", "Teklif bulunamadı");
      }

      const isAvailable = await membershipService.checkOfferAvailability(offerId);
      if (!isAvailable) {
        return fail(res, 400, "NOT_AVAILABLE", "Bu teklif kullanılamaz");
      }

      const discountedPrice = await membershipService.calculateDiscountedPrice(offer);
      const result = await membershipService.purchaseMembership(
        offerId,
        userId,
        offer.membershipType,
        offer.basePriceTokens,
        discountedPrice
      );

      if (!result) {
        return fail(res, 400, "PURCHASE_FAILED", "Satın alma başarısız");
      }

      return success(res, 200, result, "Üyelik satın alındı");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Satın alma başarısız");
    }
  }
);

router.get(
  "/membership-offers/:offerId/stats",
  async (req: Request, res: Response) => {
    try {
      const { offerId } = req.params;
      const stats = await membershipService.getOfferStats(offerId);

      if (!stats) {
        return fail(res, 404, "NOT_FOUND", "Teklif bulunamadı");
      }

      return success(res, 200, stats, "Teklif istatistikleri getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "İstatistikler getirilemedi");
    }
  }
);

router.post(
  "/video-streams/:streamId/token-packages",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const hostId = (req as any).userId;
      const { streamId } = req.params;
      const {
        packageName,
        tokenAmount,
        baseCost,
        discountedCost,
        bonusTokens,
        bonusMessage,
      } = req.body;

      if (!packageName || tokenAmount === undefined || baseCost === undefined) {
        return fail(res, 400, "VALIDATION_ERROR", "Gerekli alanlar eksik");
      }

      const pkg = await tokenService.createTokenPackage(
        streamId,
        hostId,
        packageName,
        tokenAmount,
        baseCost,
        discountedCost || baseCost,
        bonusTokens,
        bonusMessage
      );

      return success(res, 201, pkg, "Jeton paketi oluşturuldu");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Paket oluşturulamadı");
    }
  }
);

router.get(
  "/video-streams/:streamId/token-packages",
  async (req: Request, res: Response) => {
    try {
      const { streamId } = req.params;
      const packages = await tokenService.getPackagesByStream(streamId);

      return success(res, 200, packages, "Jeton paketleri getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Paketler getirilemedi");
    }
  }
);

router.get(
  "/token-packages/:packageId/value",
  async (req: Request, res: Response) => {
    try {
      const { packageId } = req.params;
      const value = await tokenService.calculatePackageValue(packageId);

      if (!value) {
        return fail(res, 404, "NOT_FOUND", "Paket bulunamadı");
      }

      return success(res, 200, value, "Paket değeri hesaplandı");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Değer hesaplanamadı");
    }
  }
);

router.post(
  "/token-packages/:packageId/purchase",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const userId = (req as any).userId;
      const { packageId } = req.params;

      const result = await tokenService.purchaseTokenPackage(packageId, userId);

      if (!result) {
        return fail(res, 400, "PURCHASE_FAILED", "Satın alma başarısız");
      }

      return success(res, 200, result, "Jeton paketi satın alındı");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Satın alma başarısız");
    }
  }
);

router.get(
  "/users/me/stream-rewards",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const userId = (req as any).userId;
      const rewards = await rewardService.getRewardsByUser(userId);

      return success(res, 200, rewards, "Ödüller getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Ödüller getirilemedi");
    }
  }
);

router.get(
  "/users/me/stream-rewards/total",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const userId = (req as any).userId;
      const total = await rewardService.getTotalRewardValue(userId);

      return success(res, 200, { totalValue: total }, "Toplam ödül hesaplandı");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Toplam hesaplanamadı");
    }
  }
);

router.post(
  "/stream-rewards/:rewardId/claim",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const userId = (req as any).userId;
      const { rewardId } = req.params;

      const result = await rewardService.claimReward(rewardId, userId);

      if (!result) {
        return fail(res, 404, "NOT_FOUND", "Ödül bulunamadı");
      }

      return success(res, 200, result, "Ödül talep edildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Ödül talep edilemedi");
    }
  }
);

router.post(
  "/stream-rewards/:rewardId/gift-to-host/:hostId",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const userId = (req as any).userId;
      const { rewardId, hostId } = req.params;

      const result = await rewardService.giftRewardToHost(rewardId, userId, hostId);

      if (!result) {
        return fail(res, 404, "NOT_FOUND", "Ödül bulunamadı");
      }

      return success(res, 200, result, "Ödül yayıncıya hediye edildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Hediye gönderilemedi");
    }
  }
);

export { router as streamMembershipOffersRouter };
