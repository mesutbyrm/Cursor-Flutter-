import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import requireAuth from '../middleware/requireAuth';

const router = Router();
const prisma = new PrismaClient();

interface ShareSettingsResponse {
  ok: boolean;
  data?: any;
  error?: string;
}

// Feature 31: Share to Social
class ShareSettingsService {
  async getOrCreateSettings(userId: string) {
    return prisma.shareSettings.upsert({
      where: { userId },
      update: {},
      create: {
        userId,
        instagramEnabled: true,
        tiktokEnabled: true,
        twitterEnabled: true,
        facebookEnabled: true,
        whatsappEnabled: true,
        defaultPrivacy: 'public',
        allowComments: true,
        allowShares: true,
      },
    });
  }

  async updateSettings(userId: string, settings: {
    instagramEnabled?: boolean;
    tiktokEnabled?: boolean;
    twitterEnabled?: boolean;
    facebookEnabled?: boolean;
    whatsappEnabled?: boolean;
    defaultPrivacy?: string;
    allowComments?: boolean;
    allowShares?: boolean;
  }) {
    return prisma.shareSettings.update({
      where: { userId },
      data: settings,
    });
  }

  async shareToSocial(userId: string, platform: string, content: string, title?: string) {
    const settings = await this.getOrCreateSettings(userId);

    if (platform === 'instagram' && !settings.instagramEnabled) {
      throw new Error('Instagram paylaşımı devre dışı');
    }
    if (platform === 'tiktok' && !settings.tiktokEnabled) {
      throw new Error('TikTok paylaşımı devre dışı');
    }
    if (platform === 'twitter' && !settings.twitterEnabled) {
      throw new Error('Twitter paylaşımı devre dışı');
    }
    if (platform === 'facebook' && !settings.facebookEnabled) {
      throw new Error('Facebook paylaşımı devre dışı');
    }
    if (platform === 'whatsapp' && !settings.whatsappEnabled) {
      throw new Error('WhatsApp paylaşımı devre dışı');
    }

    return {
      platform,
      content,
      title,
      sharedAt: new Date(),
      privacy: settings.defaultPrivacy,
    };
  }

  async deleteSettings(userId: string) {
    return prisma.shareSettings.delete({
      where: { userId },
    });
  }
}

const service = new ShareSettingsService();

router.get('/settings', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;

    const settings = await service.getOrCreateSettings(userId);

    res.json({
      ok: true,
      data: settings,
    } as ShareSettingsResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as ShareSettingsResponse);
  }
});

router.put('/settings', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const settings = req.body;

    const updated = await service.updateSettings(userId, settings);

    res.json({
      ok: true,
      data: updated,
    } as ShareSettingsResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as ShareSettingsResponse);
  }
});

router.post('/share/:platform', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const { platform } = req.params;
    const { content, title } = req.body as { content: string; title?: string };

    if (!content) {
      return res.status(400).json({
        ok: false,
        error: 'İçerik gereklidir',
      } as ShareSettingsResponse);
    }

    const share = await service.shareToSocial(userId, platform, content, title);

    res.json({
      ok: true,
      data: share,
    } as ShareSettingsResponse);
  } catch (error: any) {
    res.status(400).json({
      ok: false,
      error: error.message,
    } as ShareSettingsResponse);
  }
});

router.delete('/settings', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;

    await service.deleteSettings(userId);

    res.json({
      ok: true,
      data: { deleted: true },
    } as ShareSettingsResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as ShareSettingsResponse);
  }
});

export default router;
