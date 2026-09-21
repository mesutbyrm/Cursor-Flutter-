import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import requireAuth from '../middleware/requireAuth';

const router = Router();
const prisma = new PrismaClient();

interface VoiceSessionResponse {
  ok: boolean;
  data?: any;
  error?: string;
}

// Voice Session Service
class VoiceSessionService {
  async startSession(userId: string, roomId: string, seatNumber?: number) {
    return prisma.voiceSession.upsert({
      where: {
        roomId_userId: { roomId, userId },
      },
      update: {
        joinedAt: new Date(),
        leftAt: null,
        micEnabled: false,
      },
      create: {
        userId,
        roomId,
        seatNumber,
        joinedAt: new Date(),
        isSpeaking: false,
        micEnabled: false,
        audioLevel: 0,
        speakingTime: 0,
      },
    });
  }

  async endSession(userId: string, roomId: string) {
    return prisma.voiceSession.update({
      where: {
        roomId_userId: { roomId, userId },
      },
      data: {
        leftAt: new Date(),
      },
    });
  }

  async updateSessionState(userId: string, roomId: string, data: {
    isSpeaking?: boolean;
    micEnabled?: boolean;
    audioLevel?: number;
    speakingTime?: number;
  }) {
    return prisma.voiceSession.update({
      where: {
        roomId_userId: { roomId, userId },
      },
      data,
    });
  }

  async getSessionHistory(roomId: string, limit: number = 50, offset: number = 0) {
    return prisma.voiceSession.findMany({
      where: { roomId },
      include: {
        user: { select: { id: true, displayName: true, avatarUrl: true } },
      },
      orderBy: { joinedAt: 'desc' },
      take: limit,
      skip: offset,
    });
  }

  async getUserSessionHistory(userId: string, limit: number = 50, offset: number = 0) {
    return prisma.voiceSession.findMany({
      where: { userId },
      orderBy: { joinedAt: 'desc' },
      take: limit,
      skip: offset,
    });
  }

  async getActiveUsers(roomId: string) {
    return prisma.voiceSession.findMany({
      where: {
        roomId,
        leftAt: null,
      },
      include: {
        user: { select: { id: true, displayName: true, avatarUrl: true } },
      },
      orderBy: { joinedAt: 'asc' },
    });
  }

  async getRoomStatistics(roomId: string) {
    const sessions = await prisma.voiceSession.findMany({
      where: { roomId },
    });

    const totalUsers = new Set(sessions.map(s => s.userId)).size;
    const totalSpeakingTime = sessions.reduce((sum, s) => sum + s.speakingTime, 0);
    const avgSpeakingTime = totalUsers > 0 ? totalSpeakingTime / totalUsers : 0;
    const activeNow = sessions.filter(s => !s.leftAt).length;

    return {
      totalUsers,
      activeNow,
      totalSpeakingTime,
      avgSpeakingTime,
    };
  }

  async cleanupOldSessions(daysOld: number = 30) {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - daysOld);

    return prisma.voiceSession.deleteMany({
      where: {
        leftAt: { lt: cutoffDate },
      },
    });
  }
}

const service = new VoiceSessionService();

router.post('/sessions/start', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const { roomId, seatNumber } = req.body as { roomId: string; seatNumber?: number };

    if (!roomId) {
      return res.status(400).json({
        ok: false,
        error: 'Oda kimliği gereklidir',
      } as VoiceSessionResponse);
    }

    const session = await service.startSession(userId, roomId, seatNumber);

    res.json({
      ok: true,
      data: session,
    } as VoiceSessionResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as VoiceSessionResponse);
  }
});

router.post('/sessions/end', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const { roomId } = req.body as { roomId: string };

    if (!roomId) {
      return res.status(400).json({
        ok: false,
        error: 'Oda kimliği gereklidir',
      } as VoiceSessionResponse);
    }

    const session = await service.endSession(userId, roomId);

    res.json({
      ok: true,
      data: session,
    } as VoiceSessionResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as VoiceSessionResponse);
  }
});

router.patch('/sessions/state', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const { roomId, isSpeaking, micEnabled, audioLevel } = req.body as {
      roomId: string;
      isSpeaking?: boolean;
      micEnabled?: boolean;
      audioLevel?: number;
    };

    if (!roomId) {
      return res.status(400).json({
        ok: false,
        error: 'Oda kimliği gereklidir',
      } as VoiceSessionResponse);
    }

    const session = await service.updateSessionState(userId, roomId, {
      isSpeaking,
      micEnabled,
      audioLevel,
    });

    res.json({
      ok: true,
      data: session,
    } as VoiceSessionResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as VoiceSessionResponse);
  }
});

router.get('/sessions/room/:roomId', requireAuth, async (req, res) => {
  try {
    const { roomId } = req.params;
    const limit = parseInt(req.query.limit as string) || 50;
    const offset = parseInt(req.query.offset as string) || 0;

    const sessions = await service.getSessionHistory(roomId, limit, offset);

    res.json({
      ok: true,
      data: { sessions },
    } as VoiceSessionResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as VoiceSessionResponse);
  }
});

router.get('/sessions/user', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const limit = parseInt(req.query.limit as string) || 50;
    const offset = parseInt(req.query.offset as string) || 0;

    const sessions = await service.getUserSessionHistory(userId, limit, offset);

    res.json({
      ok: true,
      data: { sessions },
    } as VoiceSessionResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as VoiceSessionResponse);
  }
});

router.get('/sessions/active/:roomId', requireAuth, async (req, res) => {
  try {
    const { roomId } = req.params;

    const activeUsers = await service.getActiveUsers(roomId);

    res.json({
      ok: true,
      data: { activeUsers },
    } as VoiceSessionResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as VoiceSessionResponse);
  }
});

router.get('/sessions/stats/:roomId', requireAuth, async (req, res) => {
  try {
    const { roomId } = req.params;

    const stats = await service.getRoomStatistics(roomId);

    res.json({
      ok: true,
      data: stats,
    } as VoiceSessionResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as VoiceSessionResponse);
  }
});

router.post('/sessions/cleanup', requireAuth, async (req, res) => {
  try {
    const role = (req as any).userRole;
    if (role !== 'admin') {
      return res.status(403).json({
        ok: false,
        error: 'Yalnızca admin erişebilir',
      } as VoiceSessionResponse);
    }

    const { daysOld } = req.body as { daysOld?: number };
    const deleted = await service.cleanupOldSessions(daysOld);

    res.json({
      ok: true,
      data: { deletedCount: deleted.count },
    } as VoiceSessionResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as VoiceSessionResponse);
  }
});

export default router;
