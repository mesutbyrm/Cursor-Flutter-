import { Router, Request, Response } from "express";
import { prisma } from "../lib/prisma";
import { requireAuth } from "../middleware/requireAuth";
import { fail, success } from "../lib/response";

const router = Router();

class StreamAdPlacementService {
  async scheduleAd(
    streamId: string,
    hostId: string,
    adType: string,
    adContent: string,
    advertiserName: string,
    adImageUrl?: string,
    adVideoUrl?: string,
    advertiserLogoUrl?: string,
    advertiserLink?: string,
    displayPosition: string = "bottom",
    displayDuration: number = 5
  ) {
    const validAdTypes = ["banner", "overlay", "pop-up", "ticker", "host_mention"];
    if (!validAdTypes.includes(adType)) {
      return null;
    }

    return prisma.streamAdPlacement.create({
      data: {
        streamId,
        hostId,
        adType,
        adContent,
        advertiserName,
        adImageUrl,
        adVideoUrl,
        advertiserLogoUrl,
        advertiserLink,
        displayPosition,
        displayDuration,
        scheduledAt: new Date(),
      },
    });
  }

  async getStreamAds(streamId: string) {
    return prisma.streamAdPlacement.findMany({
      where: { streamId },
      orderBy: { scheduledAt: "desc" },
    });
  }

  async recordAdDisplay(adId: string) {
    return prisma.streamAdPlacement.update({
      where: { id: adId },
      data: { displayedAt: new Date() },
    });
  }

  async recordAdClick(adId: string) {
    return prisma.streamAdPlacement.update({
      where: { id: adId },
      data: { clickCount: { increment: 1 } },
    });
  }

  async getAdStats(adId: string) {
    const ad = await prisma.streamAdPlacement.findUnique({
      where: { id: adId },
    });

    if (!ad) return null;

    const impressions = ad.displayedAt ? 1 : 0;
    const ctr = impressions > 0 ? (ad.clickCount / impressions) * 100 : 0;

    return {
      adId: ad.id,
      advertiser: ad.advertiserName,
      adType: ad.adType,
      impressions,
      clicks: ad.clickCount,
      ctr: `${ctr.toFixed(2)}%`,
      displayDuration: ad.displayDuration,
      scheduledAt: ad.scheduledAt,
      displayedAt: ad.displayedAt,
    };
  }

  async deleteAd(adId: string) {
    return prisma.streamAdPlacement.delete({
      where: { id: adId },
    });
  }
}

class StreamSponsorService {
  async addSponsor(
    streamId: string,
    hostId: string,
    sponsorName: string,
    sponsorshipTier: string,
    sponsorshipAmount: number,
    sponsorMessage?: string,
    sponsorLogoUrl?: string,
    endDate?: Date
  ) {
    const validTiers = ["gold", "silver", "bronze"];
    if (!validTiers.includes(sponsorshipTier)) {
      return null;
    }

    return prisma.streamSponsor.create({
      data: {
        streamId,
        hostId,
        sponsorName,
        sponsorshipTier,
        sponsorshipAmount,
        sponsorMessage,
        sponsorLogoUrl,
        startDate: new Date(),
        endDate,
        isActive: true,
      },
    });
  }

  async getStreamSponsors(streamId: string) {
    return prisma.streamSponsor.findMany({
      where: {
        streamId,
        isActive: true,
      },
      orderBy: { sponsorshipAmount: "desc" },
    });
  }

  async getSponsorsByTier(streamId: string, tier: string) {
    return prisma.streamSponsor.findMany({
      where: {
        streamId,
        sponsorshipTier: tier,
        isActive: true,
      },
    });
  }

  async updateSponsor(sponsorId: string, data: any) {
    return prisma.streamSponsor.update({
      where: { id: sponsorId },
      data,
    });
  }

  async removeSponsor(sponsorId: string) {
    return prisma.streamSponsor.update({
      where: { id: sponsorId },
      data: { isActive: false },
    });
  }

  async getSponsorStats(sponsorId: string) {
    const sponsor = await prisma.streamSponsor.findUnique({
      where: { id: sponsorId },
    });

    if (!sponsor) return null;

    const durationDays = sponsor.endDate
      ? Math.floor((sponsor.endDate.getTime() - sponsor.startDate.getTime()) / (1000 * 60 * 60 * 24))
      : 0;

    return {
      sponsorId: sponsor.id,
      sponsorName: sponsor.sponsorName,
      tier: sponsor.sponsorshipTier,
      totalAmount: sponsor.sponsorshipAmount,
      startDate: sponsor.startDate,
      endDate: sponsor.endDate,
      durationDays,
      isActive: sponsor.isActive,
    };
  }
}

const adService = new StreamAdPlacementService();
const sponsorService = new StreamSponsorService();

router.post(
  "/video-streams/:streamId/ads/schedule",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const hostId = (req as any).userId;
      const { streamId } = req.params;
      const {
        adType,
        adContent,
        advertiserName,
        adImageUrl,
        adVideoUrl,
        advertiserLogoUrl,
        advertiserLink,
        displayPosition,
        displayDuration,
      } = req.body;

      if (!adType || !adContent || !advertiserName) {
        return fail(res, 400, "VALIDATION_ERROR", "Gerekli alanlar eksik");
      }

      const ad = await adService.scheduleAd(
        streamId,
        hostId,
        adType,
        adContent,
        advertiserName,
        adImageUrl,
        adVideoUrl,
        advertiserLogoUrl,
        advertiserLink,
        displayPosition,
        displayDuration
      );

      if (!ad) {
        return fail(res, 400, "INVALID_TYPE", "Geçersiz reklam türü");
      }

      return success(res, 201, ad, "Reklam planlandı");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Reklam planlanamadı");
    }
  }
);

router.get(
  "/video-streams/:streamId/ads",
  async (req: Request, res: Response) => {
    try {
      const { streamId } = req.params;

      const ads = await adService.getStreamAds(streamId);

      return success(res, 200, ads, "Reklamlar getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Reklamlar getirilemedi");
    }
  }
);

router.post(
  "/stream-ads/:adId/display",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { adId } = req.params;

      const ad = await adService.recordAdDisplay(adId);

      return success(res, 200, ad, "Reklam gösterildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Reklam gösterilemedi");
    }
  }
);

router.post(
  "/stream-ads/:adId/click",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { adId } = req.params;

      const ad = await adService.recordAdClick(adId);

      return success(res, 200, ad, "Reklam tıklaması kaydedildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Tıklama kaydedilemedi");
    }
  }
);

router.get(
  "/stream-ads/:adId/stats",
  async (req: Request, res: Response) => {
    try {
      const { adId } = req.params;

      const stats = await adService.getAdStats(adId);

      if (!stats) {
        return fail(res, 404, "NOT_FOUND", "Reklam bulunamadı");
      }

      return success(res, 200, stats, "İstatistikler getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "İstatistikler getirilemedi");
    }
  }
);

router.delete(
  "/stream-ads/:adId",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { adId } = req.params;

      await adService.deleteAd(adId);

      return success(res, 200, null, "Reklam silindi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Reklam silinemedi");
    }
  }
);

router.post(
  "/video-streams/:streamId/sponsors",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const hostId = (req as any).userId;
      const { streamId } = req.params;
      const {
        sponsorName,
        sponsorshipTier,
        sponsorshipAmount,
        sponsorMessage,
        sponsorLogoUrl,
        endDate,
      } = req.body;

      if (!sponsorName || !sponsorshipTier || sponsorshipAmount === undefined) {
        return fail(res, 400, "VALIDATION_ERROR", "Gerekli alanlar eksik");
      }

      const sponsor = await sponsorService.addSponsor(
        streamId,
        hostId,
        sponsorName,
        sponsorshipTier,
        sponsorshipAmount,
        sponsorMessage,
        sponsorLogoUrl,
        endDate ? new Date(endDate) : undefined
      );

      if (!sponsor) {
        return fail(res, 400, "INVALID_TIER", "Geçersiz sponsorluk tier");
      }

      return success(res, 201, sponsor, "Sponsor eklendi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Sponsor eklenemedi");
    }
  }
);

router.get(
  "/video-streams/:streamId/sponsors",
  async (req: Request, res: Response) => {
    try {
      const { streamId } = req.params;

      const sponsors = await sponsorService.getStreamSponsors(streamId);

      return success(res, 200, sponsors, "Sponsorlar getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Sponsorlar getirilemedi");
    }
  }
);

router.get(
  "/video-streams/:streamId/sponsors/tier/:tier",
  async (req: Request, res: Response) => {
    try {
      const { streamId, tier } = req.params;

      const sponsors = await sponsorService.getSponsorsByTier(streamId, tier);

      return success(res, 200, sponsors, "Tier sponsorları getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Sponsorlar getirilemedi");
    }
  }
);

router.put(
  "/stream-sponsors/:sponsorId",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { sponsorId } = req.params;
      const updateData = req.body;

      const updated = await sponsorService.updateSponsor(sponsorId, updateData);

      return success(res, 200, updated, "Sponsor güncellendi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Sponsor güncellenemedi");
    }
  }
);

router.delete(
  "/stream-sponsors/:sponsorId",
  requireAuth,
  async (req: Request, res: Response) => {
    try {
      const { sponsorId } = req.params;

      await sponsorService.removeSponsor(sponsorId);

      return success(res, 200, null, "Sponsor kaldırıldı");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "Sponsor kaldırılamadı");
    }
  }
);

router.get(
  "/stream-sponsors/:sponsorId/stats",
  async (req: Request, res: Response) => {
    try {
      const { sponsorId } = req.params;

      const stats = await sponsorService.getSponsorStats(sponsorId);

      if (!stats) {
        return fail(res, 404, "NOT_FOUND", "Sponsor bulunamadı");
      }

      return success(res, 200, stats, "Sponsor istatistikleri getirildi");
    } catch (e) {
      console.error(e);
      return fail(res, 500, "ERROR", "İstatistikler getirilemedi");
    }
  }
);

export { router as streamAdsSponsorsRouter };
