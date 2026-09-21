import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import { requireAuth } from '../middleware/requireAuth';

const router = Router();
const prisma = new PrismaClient();

interface RoleResponse {
  ok: boolean;
  data?: any;
  error?: string;
}

class VoiceRoomRoleService {
  async assignRole(roomId: string, userId: string, role: string, assignedBy: string) {
    // Rol sahibi veya moderatör olmalı
    const userRole = await prisma.voiceRoomRole.findUnique({
      where: { roomId_userId: { roomId, userId: assignedBy } },
    });

    if (!userRole || (userRole.role !== 'owner' && userRole.role !== 'moderator')) {
      throw new Error('Yetki yok: Sadece owner/moderator rol atayabilir');
    }

    return prisma.voiceRoomRole.upsert({
      where: { roomId_userId: { roomId, userId } },
      update: {
        role,
        assignedBy,
        updatedAt: new Date(),
      },
      create: {
        roomId,
        userId,
        role,
        assignedBy,
        permissions: getDefaultPermissions(role),
      },
    });
  }

  async removeRole(roomId: string, userId: string, removedBy: string) {
    const userRole = await prisma.voiceRoomRole.findUnique({
      where: { roomId_userId: { roomId, userId: removedBy } },
    });

    if (!userRole || userRole.role !== 'owner') {
      throw new Error('Yetki yok: Sadece owner rol silebilir');
    }

    return prisma.voiceRoomRole.delete({
      where: { roomId_userId: { roomId, userId } },
    });
  }

  async getRoomRoles(roomId: string) {
    return prisma.voiceRoomRole.findMany({
      where: { roomId },
      include: { user: { select: { id: true, displayName: true, avatarUrl: true } } },
      orderBy: { role: 'asc' },
    });
  }

  async getUserRole(roomId: string, userId: string) {
    return prisma.voiceRoomRole.findUnique({
      where: { roomId_userId: { roomId, userId } },
      include: { user: { select: { id: true, displayName: true, avatarUrl: true } } },
    });
  }

  async updatePermissions(roomId: string, userId: string, permissions: string[], updatedBy: string) {
    const updater = await prisma.voiceRoomRole.findUnique({
      where: { roomId_userId: { roomId, userId: updatedBy } },
    });

    if (!updater || updater.role !== 'owner') {
      throw new Error('Yetki yok: Sadece owner izin değiştirebilir');
    }

    return prisma.voiceRoomRole.update({
      where: { roomId_userId: { roomId, userId } },
      data: { permissions },
    });
  }

  async getModerators(roomId: string) {
    return prisma.voiceRoomRole.findMany({
      where: {
        roomId,
        role: { in: ['moderator', 'owner'] },
      },
      include: { user: { select: { id: true, displayName: true, avatarUrl: true } } },
    });
  }

  async getSpeakers(roomId: string) {
    return prisma.voiceRoomRole.findMany({
      where: {
        roomId,
        role: { in: ['speaker', 'moderator', 'owner'] },
      },
      include: { user: { select: { id: true, displayName: true, avatarUrl: true } } },
    });
  }
}

function getDefaultPermissions(role: string): string[] {
  const permissions: Record<string, string[]> = {
    owner: ['mute_others', 'kick', 'manage_queue', 'manage_roles', 'lock_room', 'mute_all', 'kick_all'],
    moderator: ['mute_others', 'kick', 'manage_queue'],
    speaker: ['request_speak'],
    listener: [],
  };
  return permissions[role] || [];
}

const service = new VoiceRoomRoleService();

// POST /api/chat/rooms/:roomId/roles/:userId — Rol atama
router.post('/rooms/:roomId/roles/:userId', requireAuth, async (req, res) => {
  try {
    const { roomId, userId } = req.params;
    const { role } = req.body as { role: string };

    if (!['owner', 'moderator', 'speaker', 'listener'].includes(role)) {
      return res.status(400).json({
        ok: false,
        error: 'Geçersiz rol: owner, moderator, speaker, listener',
      } as RoleResponse);
    }

    const result = await service.assignRole(roomId, userId, role, req.userId!);

    res.json({
      ok: true,
      data: result,
    } as RoleResponse);
  } catch (error: any) {
    res.status(403).json({
      ok: false,
      error: error.message,
    } as RoleResponse);
  }
});

// DELETE /api/chat/rooms/:roomId/roles/:userId — Rol silme
router.delete('/rooms/:roomId/roles/:userId', requireAuth, async (req, res) => {
  try {
    const { roomId, userId } = req.params;

    await service.removeRole(roomId, userId, req.userId!);

    res.json({
      ok: true,
      data: { userId },
    } as RoleResponse);
  } catch (error: any) {
    res.status(403).json({
      ok: false,
      error: error.message,
    } as RoleResponse);
  }
});

// GET /api/chat/rooms/:roomId/roles — Oda rollerini listele
router.get('/rooms/:roomId/roles', async (req, res) => {
  try {
    const { roomId } = req.params;
    const roles = await service.getRoomRoles(roomId);

    res.json({
      ok: true,
      data: { roles },
    } as RoleResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as RoleResponse);
  }
});

// GET /api/chat/rooms/:roomId/roles/:userId — Kullanıcı rolünü al
router.get('/rooms/:roomId/roles/:userId', async (req, res) => {
  try {
    const { roomId, userId } = req.params;
    const role = await service.getUserRole(roomId, userId);

    if (!role) {
      return res.status(404).json({
        ok: false,
        error: 'Rol bulunamadı',
      } as RoleResponse);
    }

    res.json({
      ok: true,
      data: role,
    } as RoleResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as RoleResponse);
  }
});

// GET /api/chat/rooms/:roomId/moderators — Moderatörleri listele
router.get('/rooms/:roomId/moderators', async (req, res) => {
  try {
    const { roomId } = req.params;
    const moderators = await service.getModerators(roomId);

    res.json({
      ok: true,
      data: { moderators },
    } as RoleResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as RoleResponse);
  }
});

// GET /api/chat/rooms/:roomId/speakers — Konuşan kullanıcıları listele
router.get('/rooms/:roomId/speakers', async (req, res) => {
  try {
    const { roomId } = req.params;
    const speakers = await service.getSpeakers(roomId);

    res.json({
      ok: true,
      data: { speakers },
    } as RoleResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as RoleResponse);
  }
});

// PATCH /api/chat/rooms/:roomId/roles/:userId/permissions — İzin güncelle
router.patch('/rooms/:roomId/roles/:userId/permissions', requireAuth, async (req, res) => {
  try {
    const { roomId, userId } = req.params;
    const { permissions } = req.body as { permissions: string[] };

    const result = await service.updatePermissions(roomId, userId, permissions, req.userId!);

    res.json({
      ok: true,
      data: result,
    } as RoleResponse);
  } catch (error: any) {
    res.status(403).json({
      ok: false,
      error: error.message,
    } as RoleResponse);
  }
});

export default router;
