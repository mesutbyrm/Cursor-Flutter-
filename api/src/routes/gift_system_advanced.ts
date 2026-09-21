import { Router, Request, Response } from "express";
import { prisma } from "../lib/prisma";
import { requireAuth } from "../middleware/requireAuth";
import { fail, success } from "../lib/response";

const router = Router();

class GiftComboService {
  async createCombo(
    name: string,
    requiredGiftIds: string[],
    effectType: string,
    multiplier: number,
    extraReward: number,
    emoji?: string,
    isLimited?: boolean,
    limitEndDate?: Date
  ) {
    return prisma.giftCombo.create({
      data: {
        name,
        requiredGiftIds,
        comboEffectType: effectType,
        bonusMultiplier: multiplier,
        extraTokenReward: extraReward,
        exclusiveEmoji: emoji,
        isLimited: isLimited || false,
        limitEndDate,
      },
    });
  }

  async detectCombo(giftIds: string[]): Promise<any> {
    const combos = await prisma.giftCombo.findMany({
      where: {
        isLimited: {
          not: true,
        },
      },
    });

    const activeCombos = combos.filter((c) => {
      if (c.isLimited && (!c.limitEndDate || c.limitEndDate < new Date())) {
        return false;
      }

      const requiredSet = new Set(c.requiredGiftIds);
      const giftSet = new Set(giftIds);

      return [...requiredSet].every((id) => giftSet.has(id));
    });

    return activeCombos;
  }

  async getActiveCombos() {
    return prisma.giftCombo.findMany({
      where: {
        OR: [
          { isLimited: false },
          {
            AND: [
              { isLimited: true },
              { limitEndDate: { gt: new Date() } },
            ],
          },
        ],
      },
      orderBy: { createdAt: "desc" },
    });
  }

  async calculateComboReward(
    comboId: string,
    baseGiftValue: number
  ): Promise<{ bonus: number; totalReward: number }> {
    const combo = await prisma.giftCombo.findUnique({
      where: { id: comboId },
    });

    if (!combo) return { bonus: 0, totalReward: baseGiftValue };

    const comboBonus = Math.floor(baseGiftValue * combo.bonusMultiplier);
    const extraBonus = combo.extraTokenReward;

    return {
      bonus: comboBonus + extraBonus,
      totalReward: baseGiftValue + comboBonus + extraBonus,
    };
  }
}

class GiftBoxService {
  async createGiftBox(
    streamId: string,
    hostId: string,
    name: string,
    possibleGifts: string[],
    boxPrice: number,
    expectedValue: number,
    rarity: string,
    animation?: string,
    unboxEffect?: string
  ) {
    return prisma.giftBox.create({
      data: {
        streamId,
        hostId,
        name,
        possibleGifts,
        boxPrice,
        expectedValue,
        rarity,
        animation,
        unboxEffect: unboxEffect || "default",
      },
    });
  }

  async openGiftBox(boxId: string): Promise<{ gift: string; value: number } | null> {
    const box = await prisma.giftBox.findUnique({
      where: { id: boxId },
    });

    if (!box) return null;

    const selectedGift = box.possibleGifts[Math.floor(Math.random() * box.possibleGifts.length)];
    const giftValue = Math.floor(box.expectedValue * (0.8 + Math.random() * 0.4));

    await prisma.giftBox.update({
      where: { id: boxId },
      data: {
        totalBoxesSold: { increment: 1 },
      },
    });

    return {
      gift: selectedGift,
      value: giftValue,
    };
  }

  async getBoxesByStream(streamId: string) {
    return prisma.giftBox.findMany({
      where: { streamId },
      orderBy: { createdAt: "desc" },
    });
  }

  async getBoxesByRarity(streamId: string, rarity: string) {
    return prisma.giftBox.findMany({
      where: { streamId, rarity },
      orderBy: { createdAt: "desc" },
    });
  }

  async getBoxStats(boxId: string) {
    const box = await prisma.giftBox.findUnique({
      where: { id: boxId },
    });

    if (!box) return null;

    const roi = Math.floor(((box.expectedValue - box.boxPrice) / box.boxPrice) * 100);

    return {
      boxId: box.id,
      name: box.name,
      rarity: box.rarity,
      price: box.boxPrice,
      expectedValue: box.expectedValue,
      roi: `${roi}%`,
      totalSold: box.totalBoxesSold,
      totalRevenue: box.boxPrice * box.totalBoxesSold,
      estimatedRiverValue: box.expectedValue * box.totalBoxesSold,
    };
  }
}

class AnimatedGiftEffectService {
  async createEffect(
    giftId: string,
    effectName: string,
    effectType: string,
    duration: number,
    animationUrl: string,
    soundUrl?: string,
    particleType?: string,
    particleColor?: string,
    isExclusive?: boolean,
    requiresPremium?: boolean
  ) {
    return prisma.animatedGiftEffect.create({
      data: {
        giftId,
        effectName,
        effectType,
        duration,
        animationUrl,
        soundUrl,
        particleType,
        particleColor,
        isExclusive: isExclusive || false,
        requiresPremium: requiresPremium || false,
      },
    });
  }

  async getEffectsByGift(giftId: string) {
    return prisma.animatedGiftEffect.findMany({
      where: { giftId },
    });
  }

  async getExclusiveEffects() {
    return prisma.animatedGiftEffect.findMany({
      where: { isExclusive: true },
    });
  }

  async getPremiumEffects() {
    return prisma.animatedGiftEffect.findMany({
      where: { requiresPremium: true },
    });
  }

  async triggerEffect(effectId: string) {
    const effect = await prisma.animatedGiftEffect.findUnique({
      where: { id: effectId },
    });

    if (!effect) return null;

    return {
      effectId: effect.id,
      name: effect.effectName,
      type: effect.effectType,
      duration: effect.duration,
      animation: effect.animationUrl,
      sound: effect.soundUrl,
      particles: {
        type: effect.particleType,
        color: effect.particleColor,
      },
      isExclusive: effect.isExclusive,
      requiresPremium: effect.requiresPremium,
    };
  }
}

const comboService = new GiftComboService();
const boxService = new GiftBoxService();
const effectService = new AnimatedGiftEffectService();

router.post(
  "/gifts/combos",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const {
        name,
        requiredGiftIds,
        effectType,
        multiplier,
        extraReward,
        emoji,
        isLimited,
        limitEndDate,
      } = req.body;

      if (!name || !requiredGiftIds?.length || !effectType || multiplier === undefined) {
        return fail(res, 400, "VALIDATION_ERROR", "Gerekli alanlar eksik");
      }

      const combo = await comboService.createCombo(
        name,
        requiredGiftIds,
        effectType,
        multiplier,
        extraReward || 0,
        emoji,
        isLimited,
        limitEndDate ? new Date(limitEndDate) : undefined
      );

      return success(res, 201, combo, "Hediye kombinasyonu oluşturuldu");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Kombinasyon oluşturulamadı");
    }
  }
);

router.post(
  "/gifts/detect-combo",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { giftIds } = req.body;

      if (!giftIds?.length) {
        return fail(res, 400, "VALIDATION_ERROR", "Hediye ID'leri gerekli");
      }

      const matchedCombos = await comboService.detectCombo(giftIds);

      return success(res, 200, matchedCombos, "Kombinasyonlar algılandı");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Kombinasyonlar algılanamadı");
    }
  }
);

router.get(
  "/gifts/combos/active",
  async (req: Request, res: Response) => {
    try {
      const combos = await comboService.getActiveCombos();

      return success(res, 200, combos, "Aktif kombinasyonlar getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Kombinasyonlar getirilemedi");
    }
  }
);

router.post(
  "/gifts/boxes",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const hostId = (req as any).userId;
      const {
        streamId,
        name,
        possibleGifts,
        boxPrice,
        expectedValue,
        rarity,
        animation,
        unboxEffect,
      } = req.body;

      if (!streamId || !name || !possibleGifts?.length || boxPrice === undefined) {
        return fail(res, 400, "VALIDATION_ERROR", "Gerekli alanlar eksik");
      }

      const box = await boxService.createGiftBox(
        streamId,
        hostId,
        name,
        possibleGifts,
        boxPrice,
        expectedValue || boxPrice * 1.5,
        rarity || "common",
        animation,
        unboxEffect
      );

      return success(res, 201, box, "Hediye kutusu oluşturuldu");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Kutu oluşturulamadı");
    }
  }
);

router.post(
  "/gifts/boxes/:boxId/open",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { boxId } = req.params;

      const result = await boxService.openGiftBox(boxId);

      if (!result) {
        return fail(res, 404, "NOT_FOUND", "Kutu bulunamadı");
      }

      return success(res, 200, result, "Kutu açıldı");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Kutu açılamadı");
    }
  }
);

router.get(
  "/video-streams/:streamId/gift-boxes",
  async (req: Request, res: Response) => {
    try {
      const { streamId } = req.params;
      const boxes = await boxService.getBoxesByStream(streamId);

      return success(res, 200, boxes, "Kutuları getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Kutuları getirilemedi");
    }
  }
);

router.get(
  "/gifts/boxes/:boxId/stats",
  async (req: Request, res: Response) => {
    try {
      const { boxId } = req.params;
      const stats = await boxService.getBoxStats(boxId);

      if (!stats) {
        return fail(res, 404, "NOT_FOUND", "Kutu bulunamadı");
      }

      return success(res, 200, stats, "Kutu istatistikleri getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "İstatistikler getirilemedi");
    }
  }
);

router.post(
  "/gifts/effects",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const {
        giftId,
        effectName,
        effectType,
        duration,
        animationUrl,
        soundUrl,
        particleType,
        particleColor,
        isExclusive,
        requiresPremium,
      } = req.body;

      if (!giftId || !effectName || !effectType || duration === undefined || !animationUrl) {
        return fail(res, 400, "VALIDATION_ERROR", "Gerekli alanlar eksik");
      }

      const effect = await effectService.createEffect(
        giftId,
        effectName,
        effectType,
        duration,
        animationUrl,
        soundUrl,
        particleType,
        particleColor,
        isExclusive,
        requiresPremium
      );

      return success(res, 201, effect, "Efekt oluşturuldu");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Efekt oluşturulamadı");
    }
  }
);

router.get(
  "/gifts/:giftId/effects",
  async (req: Request, res: Response) => {
    try {
      const { giftId } = req.params;
      const effects = await effectService.getEffectsByGift(giftId);

      return success(res, 200, effects, "Efektler getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Efektler getirilemedi");
    }
  }
);

router.get(
  "/gifts/effects/exclusive",
  async (req: Request, res: Response) => {
    try {
      const effects = await effectService.getExclusiveEffects();

      return success(res, 200, effects, "Özel efektler getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Efektler getirilemedi");
    }
  }
);

router.get(
  "/gifts/effects/premium",
  async (req: Request, res: Response) => {
    try {
      const effects = await effectService.getPremiumEffects();

      return success(res, 200, effects, "Premium efektler getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Efektler getirilemedi");
    }
  }
);

export { router as giftSystemAdvancedRouter };
