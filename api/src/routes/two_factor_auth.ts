import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import requireAuth from '../middleware/requireAuth';
import crypto from 'crypto';

const router = Router();
const prisma = new PrismaClient();

interface TwoFactorResponse {
  ok: boolean;
  data?: any;
  error?: string;
}

// Feature 35: Two-Factor Authentication
class TwoFactorAuthService {
  generateSecret(): string {
    return crypto.randomBytes(32).toString('hex').substring(0, 32);
  }

  generateBackupCodes(): string[] {
    const codes: string[] = [];
    for (let i = 0; i < 10; i++) {
      codes.push(crypto.randomBytes(4).toString('hex').toUpperCase());
    }
    return codes;
  }

  generateToken(): string {
    return crypto.randomBytes(32).toString('hex');
  }

  async enableTwoFactor(userId: string, method: string = 'totp') {
    const secret = this.generateSecret();
    const backupCodes = this.generateBackupCodes();

    return prisma.twoFactorAuth.upsert({
      where: { userId },
      update: {
        enabled: false,
        method,
        secret,
        backupCodes,
      },
      create: {
        userId,
        enabled: false,
        method,
        secret,
        backupCodes,
      },
    });
  }

  async verifyTwoFactor(userId: string, code: string) {
    const twoFactor = await prisma.twoFactorAuth.findUnique({
      where: { userId },
    });

    if (!twoFactor) {
      throw new Error('İki faktörlü kimlik doğrulama etkinleştirilmedi');
    }

    if (twoFactor.backupCodes.includes(code)) {
      const updatedBackupCodes = twoFactor.backupCodes.filter(c => c !== code);
      await prisma.twoFactorAuth.update({
        where: { userId },
        data: { backupCodes: updatedBackupCodes },
      });
      return { verified: true, type: 'backup' };
    }

    return { verified: false };
  }

  async confirmEnable(userId: string) {
    return prisma.twoFactorAuth.update({
      where: { userId },
      data: {
        enabled: true,
        verifiedAt: new Date(),
      },
    });
  }

  async disableTwoFactor(userId: string) {
    return prisma.twoFactorAuth.update({
      where: { userId },
      data: { enabled: false },
    });
  }

  async createSession(userId: string) {
    const token = this.generateToken();
    const code = Math.random().toString().substring(2, 8);

    return prisma.twoFactorSession.create({
      data: {
        userId,
        token,
        code,
        expiresAt: new Date(Date.now() + 10 * 60 * 1000),
      },
    });
  }

  async verifySession(token: string, code: string) {
    const session = await prisma.twoFactorSession.findUnique({
      where: { token },
    });

    if (!session || session.expiresAt < new Date()) {
      throw new Error('Oturum süresi doldu');
    }

    if (session.code !== code) {
      throw new Error('Kod hatalı');
    }

    return prisma.twoFactorSession.update({
      where: { token },
      data: { verified: true },
    });
  }

  async getTwoFactorStatus(userId: string) {
    const twoFactor = await prisma.twoFactorAuth.findUnique({
      where: { userId },
    });

    return {
      enabled: twoFactor?.enabled || false,
      method: twoFactor?.method || null,
      backupCodesRemaining: twoFactor?.backupCodes?.length || 0,
    };
  }
}

const service = new TwoFactorAuthService();

router.post('/enable', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const { method } = req.body as { method?: string };

    const twoFactor = await service.enableTwoFactor(userId, method);

    res.json({
      ok: true,
      data: {
        secret: twoFactor.secret,
        backupCodes: twoFactor.backupCodes,
      },
    } as TwoFactorResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as TwoFactorResponse);
  }
});

router.post('/verify', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const { code } = req.body as { code: string };

    if (!code) {
      return res.status(400).json({
        ok: false,
        error: 'Kod gereklidir',
      } as TwoFactorResponse);
    }

    const result = await service.verifyTwoFactor(userId, code);

    res.json({
      ok: true,
      data: result,
    } as TwoFactorResponse);
  } catch (error: any) {
    res.status(400).json({
      ok: false,
      error: error.message,
    } as TwoFactorResponse);
  }
});

router.post('/confirm', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;

    const twoFactor = await service.confirmEnable(userId);

    res.json({
      ok: true,
      data: { enabled: twoFactor.enabled },
    } as TwoFactorResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as TwoFactorResponse);
  }
});

router.post('/disable', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;

    const twoFactor = await service.disableTwoFactor(userId);

    res.json({
      ok: true,
      data: { enabled: twoFactor.enabled },
    } as TwoFactorResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as TwoFactorResponse);
  }
});

router.post('/session/create', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;

    const session = await service.createSession(userId);

    res.json({
      ok: true,
      data: { token: session.token },
    } as TwoFactorResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as TwoFactorResponse);
  }
});

router.post('/session/verify', async (req, res) => {
  try {
    const { token, code } = req.body as { token: string; code: string };

    if (!token || !code) {
      return res.status(400).json({
        ok: false,
        error: 'Token ve kod gereklidir',
      } as TwoFactorResponse);
    }

    const session = await service.verifySession(token, code);

    res.json({
      ok: true,
      data: { verified: session.verified },
    } as TwoFactorResponse);
  } catch (error: any) {
    res.status(400).json({
      ok: false,
      error: error.message,
    } as TwoFactorResponse);
  }
});

router.get('/status', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;

    const status = await service.getTwoFactorStatus(userId);

    res.json({
      ok: true,
      data: status,
    } as TwoFactorResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as TwoFactorResponse);
  }
});

export default router;
