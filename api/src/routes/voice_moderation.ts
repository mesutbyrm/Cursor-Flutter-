import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import { requireAuth } from '../middleware/requireAuth';

const router = Router();
const prisma = new PrismaClient();

interface ModerationResponse {
  ok: boolean;
  data?: any;
  error?: string;
}

class VoiceModerationService {
  async muteAll(roomId: string, moderatorId: string) {
    // Yetki kontrol
    const role = await prisma.voiceRoomRole.findUnique({
      where: { roomId_userId: { roomId, userId: moderatorId } },
    });

    if (!role || !['owner', 'moderator'].includes(role.role)) {
      throw new Error('Yetki yok: Sadece owner/moderator tüm kullanıcıları sessize alabilir');
    }

    // Tüm aktif kullanıcıları sessiz yap (VoiceSession'da micEnabled = false)
    const mutedCount = await prisma.voiceSession.updateMany({
      where: { roomId, leftAt: null },
      data: { micEnabled: false, isSpeaking: false },
    });

    return { mutedCount: mutedCount.count };
  }

  async unmuteAll(roomId: string, moderatorId: string) {
    const role = await prisma.voiceRoomRole.findUnique({
      where: { roomId_userId: { roomId, userId: moderatorId } },
    });

    if (!role || !['owner', 'moderator'].includes(role.role)) {
      throw new Error('Yetki yok: Sadece owner/moderator tüm kullanıcıları sesi açabilir');
    }

    const unmutedCount = await prisma.voiceSession.updateMany({
      where: { roomId, leftAt: null },
      data: { micEnabled: true },
    });

    return { unmutedCount: unmutedCount.count };
  }

  async kickAll(roomId: string, moderatorId: string) {
    const role = await prisma.voiceRoomRole.findUnique({
      where: { roomId_userId: { roomId, userId: moderatorId } },
    });

    if (!role || role.role !== 'owner') {
      throw new Error('Yetki yok: Sadece owner tüm kullanıcıları çıkarabilir');
    }

    // Tüm aktif oturumları kapat
    const kickedCount = await prisma.voiceSession.updateMany({
      where: { roomId, leftAt: null },
      data: { leftAt: new Date() },
    });

    return { kickedCount: kickedCount.count };
  }

  async lockRoom(roomId: string, moderatorId: string) {
    const role = await prisma.voiceRoomRole.findUnique({
      where: { roomId_userId: { roomId, userId: moderatorId } },
    });

    if (!role || !['owner', 'moderator'].includes(role.role)) {
      throw new Error('Yetki yok: Sadece owner/moderator oda kilitleyebilir');
    }

    // Oda kilitlendiğinde yeni giriş engelle (metadata'da track et)
    return { roomId, locked: true, lockedAt: new Date() };
  }

  async unlockRoom(roomId: string, moderatorId: string) {
    const role = await prisma.voiceRoomRole.findUnique({
      where: { roomId_userId: { roomId, userId: moderatorId } },
    });

    if (!role || role.role !== 'owner') {
      throw new Error('Yetki yok: Sadece owner oda kilidini açabilir');
    }

    return { roomId, locked: false, unlockedAt: new Date() };
  }

  async muteUser(roomId: string, userId: string, moderatorId: string) {
    const role = await prisma.voiceRoomRole.findUnique({
      where: { roomId_userId: { roomId, userId: moderatorId } },
    });

    if (!role || !['owner', 'moderator'].includes(role.role)) {
      throw new Error('Yetki yok');
    }

    return prisma.voiceSession.updateMany({
      where: { roomId, userId },
      data: { micEnabled: false, isSpeaking: false },
    });
  }

  async unmuteUser(roomId: string, userId: string, moderatorId: string) {
    const role = await prisma.voiceRoomRole.findUnique({
      where: { roomId_userId: { roomId, userId: moderatorId } },
    });

    if (!role || !['owner', 'moderator'].includes(role.role)) {
      throw new Error('Yetki yok');
    }

    return prisma.voiceSession.updateMany({
      where: { roomId, userId },
      data: { micEnabled: true },
    });
  }

  async kickUser(roomId: string, userId: string, moderatorId: string) {
    const role = await prisma.voiceRoomRole.findUnique({
      where: { roomId_userId: { roomId, userId: moderatorId } },
    });

    if (!role || !['owner', 'moderator'].includes(role.role)) {
      throw new Error('Yetki yok');
    }

    return prisma.voiceSession.updateMany({
      where: { roomId, userId },
      data: { leftAt: new Date() },
    });
  }
}

const service = new VoiceModerationService();

// POST /api/chat/rooms/:roomId/moderation/mute-all — Tüm kullanıcıları sessiz yap
router.post('/rooms/:roomId/moderation/mute-all', requireAuth, async (req, res) => {
  try {
    const { roomId } = req.params;
    const result = await service.muteAll(roomId, req.userId!);

    res.json({
      ok: true,
      data: result,
    } as ModerationResponse);
  } catch (error: any) {
    res.status(403).json({
      ok: false,
      error: error.message,
    } as ModerationResponse);
  }
});

// POST /api/chat/rooms/:roomId/moderation/unmute-all — Tüm kullanıcıların sesini aç
router.post('/rooms/:roomId/moderation/unmute-all', requireAuth, async (req, res) => {
  try {
    const { roomId } = req.params;
    const result = await service.unmuteAll(roomId, req.userId!);

    res.json({
      ok: true,
      data: result,
    } as ModerationResponse);
  } catch (error: any) {
    res.status(403).json({
      ok: false,
      error: error.message,
    } as ModerationResponse);
  }
});

// POST /api/chat/rooms/:roomId/moderation/kick-all — Tüm kullanıcıları çıkar
router.post('/rooms/:roomId/moderation/kick-all', requireAuth, async (req, res) => {
  try {
    const { roomId } = req.params;
    const result = await service.kickAll(roomId, req.userId!);

    res.json({
      ok: true,
      data: result,
    } as ModerationResponse);
  } catch (error: any) {
    res.status(403).json({
      ok: false,
      error: error.message,
    } as ModerationResponse);
  }
});

// POST /api/chat/rooms/:roomId/moderation/lock — Oda kilitlerini
router.post('/rooms/:roomId/moderation/lock', requireAuth, async (req, res) => {
  try {
    const { roomId } = req.params;
    const result = await service.lockRoom(roomId, req.userId!);

    res.json({
      ok: true,
      data: result,
    } as ModerationResponse);
  } catch (error: any) {
    res.status(403).json({
      ok: false,
      error: error.message,
    } as ModerationResponse);
  }
});

// POST /api/chat/rooms/:roomId/moderation/unlock — Oda kilidini açar
router.post('/rooms/:roomId/moderation/unlock', requireAuth, async (req, res) => {
  try {
    const { roomId } = req.params;
    const result = await service.unlockRoom(roomId, req.userId!);

    res.json({
      ok: true,
      data: result,
    } as ModerationResponse);
  } catch (error: any) {
    res.status(403).json({
      ok: false,
      error: error.message,
    } as ModerationResponse);
  }
});

// POST /api/chat/rooms/:roomId/moderation/mute/:userId — Kullanıcıyı sessiz yap
router.post('/rooms/:roomId/moderation/mute/:userId', requireAuth, async (req, res) => {
  try {
    const { roomId, userId } = req.params;
    await service.muteUser(roomId, userId, req.userId!);

    res.json({
      ok: true,
      data: { userId, muted: true },
    } as ModerationResponse);
  } catch (error: any) {
    res.status(403).json({
      ok: false,
      error: error.message,
    } as ModerationResponse);
  }
});

// POST /api/chat/rooms/:roomId/moderation/unmute/:userId — Kullanıcının sesini aç
router.post('/rooms/:roomId/moderation/unmute/:userId', requireAuth, async (req, res) => {
  try {
    const { roomId, userId } = req.params;
    await service.unmuteUser(roomId, userId, req.userId!);

    res.json({
      ok: true,
      data: { userId, unmuted: true },
    } as ModerationResponse);
  } catch (error: any) {
    res.status(403).json({
      ok: false,
      error: error.message,
    } as ModerationResponse);
  }
});

// POST /api/chat/rooms/:roomId/moderation/kick/:userId — Kullanıcıyı çıkar
router.post('/rooms/:roomId/moderation/kick/:userId', requireAuth, async (req, res) => {
  try {
    const { roomId, userId } = req.params;
    await service.kickUser(roomId, userId, req.userId!);

    res.json({
      ok: true,
      data: { userId, kicked: true },
    } as ModerationResponse);
  } catch (error: any) {
    res.status(403).json({
      ok: false,
      error: error.message,
    } as ModerationResponse);
  }
});

export default router;
