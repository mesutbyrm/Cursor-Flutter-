import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import requireAuth from '../middleware/requireAuth';
import crypto from 'crypto';

const router = Router();
const prisma = new PrismaClient();

interface AgoraTokenResponse {
  ok: boolean;
  data?: any;
  error?: string;
}

// Agora RTC Service
class AgoraTokenService {
  private agoraAppId: string;
  private agoraAppCertificate: string;

  constructor() {
    this.agoraAppId = process.env.AGORA_APP_ID || 'test_app_id';
    this.agoraAppCertificate = process.env.AGORA_APP_CERTIFICATE || 'test_certificate';
  }

  generateToken(channelName: string, agoraUid: number, expirationTimeInSeconds: number = 3600): string {
    const timestamp = Math.floor(Date.now() / 1000);
    const expirationTime = timestamp + expirationTimeInSeconds;

    // Basit token simulasyonu (gerçekte RtcTokenBuilder kullanılacak)
    const payload = {
      appId: this.agoraAppId,
      channelName,
      uid: agoraUid,
      issuedAt: timestamp,
      expiration: expirationTime,
      salt: crypto.randomBytes(32).toString('hex'),
    };

    const token = Buffer.from(JSON.stringify(payload)).toString('base64');
    return token;
  }

  async createToken(userId: string, channelName: string, agoraUid?: number) {
    const uid = agoraUid || Math.floor(Math.random() * 1000000);
    const token = this.generateToken(channelName, uid);
    const expirationTime = new Date(Date.now() + 3600 * 1000); // 1 saat

    const agoraToken = await prisma.agoraToken.create({
      data: {
        userId,
        channelName,
        token,
        agoraUid: uid,
        tokenExpiration: expirationTime,
      },
    });

    return {
      token,
      channelName,
      uid,
      expiresAt: expirationTime.toISOString(),
    };
  }

  async getActiveToken(userId: string, channelName: string) {
    const token = await prisma.agoraToken.findFirst({
      where: {
        userId,
        channelName,
        tokenExpiration: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (token) {
      return {
        token: token.token,
        channelName: token.channelName,
        uid: token.agoraUid,
        expiresAt: token.tokenExpiration.toISOString(),
      };
    }

    return null;
  }

  async revokeToken(tokenId: string) {
    return prisma.agoraToken.delete({
      where: { id: tokenId },
    });
  }

  async cleanupExpiredTokens() {
    return prisma.agoraToken.deleteMany({
      where: {
        tokenExpiration: { lt: new Date() },
      },
    });
  }
}

const service = new AgoraTokenService();

router.post('/token', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const { channelName, agoraUid } = req.body as { channelName: string; agoraUid?: number };

    if (!channelName) {
      return res.status(400).json({
        ok: false,
        error: 'Kanal adı gereklidir',
      } as AgoraTokenResponse);
    }

    // Aktif token varsa geri dön, yoksa yeni oluştur
    let tokenData = await service.getActiveToken(userId, channelName);
    if (!tokenData) {
      tokenData = await service.createToken(userId, channelName, agoraUid);
    }

    res.json({
      ok: true,
      data: tokenData,
    } as AgoraTokenResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as AgoraTokenResponse);
  }
});

router.get('/token/:channelName', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const { channelName } = req.params;

    const tokenData = await service.getActiveToken(userId, channelName);

    if (!tokenData) {
      return res.status(404).json({
        ok: false,
        error: 'Token bulunamadı',
      } as AgoraTokenResponse);
    }

    res.json({
      ok: true,
      data: tokenData,
    } as AgoraTokenResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as AgoraTokenResponse);
  }
});

router.delete('/token/:tokenId', requireAuth, async (req, res) => {
  try {
    const { tokenId } = req.params;

    await service.revokeToken(tokenId);

    res.json({
      ok: true,
      data: { revoked: true },
    } as AgoraTokenResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as AgoraTokenResponse);
  }
});

router.post('/cleanup', requireAuth, async (req, res) => {
  try {
    const role = (req as any).userRole;
    if (role !== 'admin') {
      return res.status(403).json({
        ok: false,
        error: 'Yalnızca admin erişebilir',
      } as AgoraTokenResponse);
    }

    const deleted = await service.cleanupExpiredTokens();

    res.json({
      ok: true,
      data: { deletedCount: deleted.count },
    } as AgoraTokenResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as AgoraTokenResponse);
  }
});

export default router;
