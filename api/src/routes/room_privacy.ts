import { Router, Request, Response } from "express";
import { PrismaClient } from "@prisma/client";
import { requireAuth } from "../middleware/requireAuth";

const prisma = new PrismaClient();
const router = Router();

class RoomPrivacyService {
  async createRoomPrivacy(
    roomId: string,
    data: {
      privacyLevel: string;
      password?: string;
      allowedUserIds?: string[];
      blockedUserIds?: string[];
    }
  ) {
    const isPasswordProtected = !!data.password;
    const inviteOnly = data.privacyLevel === "invite-only";
    const friendsOnly = data.privacyLevel === "friends-only";

    return prisma.roomPrivacy.upsert({
      where: { roomId },
      create: {
        roomId,
        privacyLevel: data.privacyLevel,
        password: data.password,
        allowedUserIds: data.allowedUserIds || [],
        blockedUserIds: data.blockedUserIds || [],
        isPasswordProtected,
        inviteOnly,
        friendsOnly,
      },
      update: {
        privacyLevel: data.privacyLevel,
        password: data.password,
        allowedUserIds: data.allowedUserIds,
        blockedUserIds: data.blockedUserIds,
        isPasswordProtected,
        inviteOnly,
        friendsOnly,
      },
    });
  }

  async getRoomPrivacy(roomId: string) {
    return prisma.roomPrivacy.findUnique({
      where: { roomId },
      select: {
        id: true,
        roomId: true,
        privacyLevel: true,
        isPasswordProtected: true,
        inviteOnly: true,
        friendsOnly: true,
      },
    });
  }

  async verifyRoomAccess(roomId: string, userId: string, password?: string) {
    const privacy = await prisma.roomPrivacy.findUnique({
      where: { roomId },
    });

    if (!privacy) {
      return { allowed: true, reason: "Oda gizlilik ayarları bulunamadı" };
    }

    if (privacy.blockedUserIds.includes(userId)) {
      return { allowed: false, reason: "Bu odaya erişim izni yok" };
    }

    if (privacy.privacyLevel === "public") {
      return { allowed: true, reason: "Halka açık oda" };
    }

    if (privacy.privacyLevel === "password-protected") {
      if (!password || password !== privacy.password) {
        return { allowed: false, reason: "Şifre yanlış" };
      }
      return { allowed: true, reason: "Şifre doğru" };
    }

    if (privacy.privacyLevel === "invite-only") {
      if (!privacy.allowedUserIds.includes(userId)) {
        return { allowed: false, reason: "Davet gereklidir" };
      }
      return { allowed: true, reason: "Kullanıcı davetli" };
    }

    if (privacy.privacyLevel === "friends-only") {
      return { allowed: false, reason: "Sadece arkadaşlar erişebilir" };
    }

    return { allowed: false, reason: "Bilinmeyen gizlilik seviyesi" };
  }

  async addAllowedUser(roomId: string, userId: string) {
    const privacy = await prisma.roomPrivacy.findUnique({
      where: { roomId },
    });

    if (!privacy) return null;

    const allowedUserIds = Array.from(new Set([...privacy.allowedUserIds, userId]));

    return prisma.roomPrivacy.update({
      where: { roomId },
      data: { allowedUserIds },
    });
  }

  async removeAllowedUser(roomId: string, userId: string) {
    const privacy = await prisma.roomPrivacy.findUnique({
      where: { roomId },
    });

    if (!privacy) return null;

    const allowedUserIds = privacy.allowedUserIds.filter((id) => id !== userId);

    return prisma.roomPrivacy.update({
      where: { roomId },
      data: { allowedUserIds },
    });
  }

  async blockUser(roomId: string, userId: string) {
    const privacy = await prisma.roomPrivacy.findUnique({
      where: { roomId },
    });

    if (!privacy) return null;

    const blockedUserIds = Array.from(new Set([...privacy.blockedUserIds, userId]));

    return prisma.roomPrivacy.update({
      where: { roomId },
      data: { blockedUserIds },
    });
  }

  async unblockUser(roomId: string, userId: string) {
    const privacy = await prisma.roomPrivacy.findUnique({
      where: { roomId },
    });

    if (!privacy) return null;

    const blockedUserIds = privacy.blockedUserIds.filter((id) => id !== userId);

    return prisma.roomPrivacy.update({
      where: { roomId },
      data: { blockedUserIds },
    });
  }
}

const service = new RoomPrivacyService();

router.get("/rooms/:roomId/privacy", async (req: Request, res: Response) => {
  try {
    const { roomId } = req.params;
    const privacy = await service.getRoomPrivacy(roomId);

    if (!privacy) {
      return res.status(404).json({
        success: false,
        message: "Gizlilik ayarları bulunamadı",
      });
    }

    return res.status(200).json({
      success: true,
      data: privacy,
    });
  } catch (error) {
    console.error("getRoomPrivacy error:", error);
    return res.status(500).json({
      success: false,
      message: "Gizlilik ayarları alınamadı",
    });
  }
});

router.post("/rooms/:roomId/privacy", requireAuth, async (req: Request, res: Response) => {
  try {
    const { roomId } = req.params;
    const { privacyLevel, password, allowedUserIds, blockedUserIds } = req.body;

    const privacy = await service.createRoomPrivacy(roomId, {
      privacyLevel,
      password,
      allowedUserIds,
      blockedUserIds,
    });

    return res.status(201).json({
      success: true,
      data: privacy,
    });
  } catch (error) {
    console.error("createRoomPrivacy error:", error);
    return res.status(500).json({
      success: false,
      message: "Gizlilik ayarları oluşturulamadı",
    });
  }
});

router.post("/rooms/:roomId/verify-access", async (req: Request, res: Response) => {
  try {
    const { roomId } = req.params;
    const { userId, password } = req.body;

    const result = await service.verifyRoomAccess(roomId, userId, password);

    return res.status(200).json({
      success: result.allowed,
      ...result,
    });
  } catch (error) {
    console.error("verifyRoomAccess error:", error);
    return res.status(500).json({
      success: false,
      message: "Erişim doğrulanamadı",
    });
  }
});

router.post("/rooms/:roomId/allow-user/:userId", requireAuth, async (req: Request, res: Response) => {
  try {
    const { roomId, userId } = req.params;

    const privacy = await service.addAllowedUser(roomId, userId);

    return res.status(200).json({
      success: true,
      data: privacy,
    });
  } catch (error) {
    console.error("addAllowedUser error:", error);
    return res.status(500).json({
      success: false,
      message: "Kullanıcı eklenemedi",
    });
  }
});

router.delete("/rooms/:roomId/allow-user/:userId", requireAuth, async (req: Request, res: Response) => {
  try {
    const { roomId, userId } = req.params;

    const privacy = await service.removeAllowedUser(roomId, userId);

    return res.status(200).json({
      success: true,
      data: privacy,
    });
  } catch (error) {
    console.error("removeAllowedUser error:", error);
    return res.status(500).json({
      success: false,
      message: "Kullanıcı kaldırılamadı",
    });
  }
});

router.post("/rooms/:roomId/block-user/:userId", requireAuth, async (req: Request, res: Response) => {
  try {
    const { roomId, userId } = req.params;

    const privacy = await service.blockUser(roomId, userId);

    return res.status(200).json({
      success: true,
      data: privacy,
    });
  } catch (error) {
    console.error("blockUser error:", error);
    return res.status(500).json({
      success: false,
      message: "Kullanıcı engellenemedi",
    });
  }
});

router.delete("/rooms/:roomId/block-user/:userId", requireAuth, async (req: Request, res: Response) => {
  try {
    const { roomId, userId } = req.params;

    const privacy = await service.unblockUser(roomId, userId);

    return res.status(200).json({
      success: true,
      data: privacy,
    });
  } catch (error) {
    console.error("unblockUser error:", error);
    return res.status(500).json({
      success: false,
      message: "Engel kaldırılamadı",
    });
  }
});

export const roomPrivacyRouter = router;
