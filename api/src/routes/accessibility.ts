import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import requireAuth from '../middleware/requireAuth';

const router = Router();
const prisma = new PrismaClient();

interface AccessibilityResponse {
  ok: boolean;
  data?: any;
  error?: string;
}

// Feature 36: Accessibility Settings
class AccessibilityService {
  async getOrCreateSettings(userId: string) {
    return prisma.accessibilitySettings.upsert({
      where: { userId },
      update: {},
      create: {
        userId,
        screenReaderEnabled: false,
        highContrastEnabled: false,
        largeTextEnabled: false,
        reduceMotionEnabled: false,
        captionsEnabled: true,
        keyboardNavigationEnabled: true,
      },
    });
  }

  async updateSettings(userId: string, settings: {
    screenReaderEnabled?: boolean;
    highContrastEnabled?: boolean;
    largeTextEnabled?: boolean;
    reduceMotionEnabled?: boolean;
    captionsEnabled?: boolean;
    keyboardNavigationEnabled?: boolean;
  }) {
    return prisma.accessibilitySettings.update({
      where: { userId },
      data: settings,
    });
  }

  async deleteSettings(userId: string) {
    return prisma.accessibilitySettings.delete({
      where: { userId },
    });
  }

  async getAccessibilityProfile(userId: string) {
    const settings = await this.getOrCreateSettings(userId);

    const profile = {
      settings,
      activeFeatures: [] as string[],
      recommendations: [] as string[],
    };

    if (settings.screenReaderEnabled) {
      profile.activeFeatures.push('Ekran okuyucu');
    }
    if (settings.highContrastEnabled) {
      profile.activeFeatures.push('Yüksek kontrastlı');
    }
    if (settings.largeTextEnabled) {
      profile.activeFeatures.push('Büyük metin');
    }
    if (settings.reduceMotionEnabled) {
      profile.activeFeatures.push('Hareketi azalt');
    }

    if (!settings.screenReaderEnabled && settings.reduceMotionEnabled) {
      profile.recommendations.push('Ekran okuyucu etkinleştirmeyi düşünün');
    }

    return profile;
  }
}

const service = new AccessibilityService();

router.get('/settings', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;

    const settings = await service.getOrCreateSettings(userId);

    res.json({
      ok: true,
      data: settings,
    } as AccessibilityResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as AccessibilityResponse);
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
    } as AccessibilityResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as AccessibilityResponse);
  }
});

router.get('/profile', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;

    const profile = await service.getAccessibilityProfile(userId);

    res.json({
      ok: true,
      data: profile,
    } as AccessibilityResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as AccessibilityResponse);
  }
});

router.delete('/settings', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;

    await service.deleteSettings(userId);

    res.json({
      ok: true,
      data: { deleted: true },
    } as AccessibilityResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as AccessibilityResponse);
  }
});

export default router;
