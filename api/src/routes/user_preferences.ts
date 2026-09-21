import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import requireAuth from '../middleware/requireAuth';

const router = Router();
const prisma = new PrismaClient();

interface PreferencesResponse {
  ok: boolean;
  data?: any;
  error?: string;
}

// Feature 33: User Preferences & Animations
class UserPreferencesService {
  async getOrCreatePreferences(userId: string) {
    return prisma.userPreferences.upsert({
      where: { userId },
      update: {},
      create: {
        userId,
        theme: 'system',
        accentColor: 'cyan',
        fontSize: 'medium',
        animationsEnabled: true,
        soundEnabled: true,
        hapticEnabled: true,
        language: 'tr',
        timeFormat: '24h',
        dateFormat: 'dd.MM.yyyy',
      },
      include: { animationConfig: true },
    });
  }

  async updatePreferences(userId: string, preferences: {
    theme?: string;
    accentColor?: string;
    fontSize?: string;
    animationsEnabled?: boolean;
    soundEnabled?: boolean;
    hapticEnabled?: boolean;
    language?: string;
    timeFormat?: string;
    dateFormat?: string;
  }) {
    return prisma.userPreferences.update({
      where: { userId },
      data: preferences,
      include: { animationConfig: true },
    });
  }

  async getAnimationConfig(userId: string) {
    let config = await prisma.animationConfig.findUnique({
      where: { userId },
    });

    if (!config) {
      config = await prisma.animationConfig.create({
        data: {
          userId,
          pageTransitionDuration: 300,
          cardFlipDuration: 500,
          scrollAnimationEnabled: true,
          parallaxEnabled: true,
          lightEffectsEnabled: true,
        },
      });
    }

    return config;
  }

  async updateAnimationConfig(userId: string, config: {
    pageTransitionDuration?: number;
    cardFlipDuration?: number;
    scrollAnimationEnabled?: boolean;
    parallaxEnabled?: boolean;
    lightEffectsEnabled?: boolean;
  }) {
    return prisma.animationConfig.update({
      where: { userId },
      data: config,
    });
  }

  async deletePreferences(userId: string) {
    await prisma.animationConfig.deleteMany({ where: { userId } });
    return prisma.userPreferences.delete({
      where: { userId },
    });
  }
}

const service = new UserPreferencesService();

router.get('/preferences', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;

    const preferences = await service.getOrCreatePreferences(userId);

    res.json({
      ok: true,
      data: preferences,
    } as PreferencesResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as PreferencesResponse);
  }
});

router.put('/preferences', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const preferences = req.body;

    const updated = await service.updatePreferences(userId, preferences);

    res.json({
      ok: true,
      data: updated,
    } as PreferencesResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as PreferencesResponse);
  }
});

router.get('/animations', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;

    const config = await service.getAnimationConfig(userId);

    res.json({
      ok: true,
      data: config,
    } as PreferencesResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as PreferencesResponse);
  }
});

router.put('/animations', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const config = req.body;

    const updated = await service.updateAnimationConfig(userId, config);

    res.json({
      ok: true,
      data: updated,
    } as PreferencesResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as PreferencesResponse);
  }
});

router.delete('/preferences', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;

    await service.deletePreferences(userId);

    res.json({
      ok: true,
      data: { deleted: true },
    } as PreferencesResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as PreferencesResponse);
  }
});

export default router;
