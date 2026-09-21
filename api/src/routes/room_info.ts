import { Router, Request, Response } from "express";
import { PrismaClient } from "@prisma/client";
import { requireAuth } from "../middleware/requireAuth";

const prisma = new PrismaClient();
const router = Router();

class RoomInfoService {
  async createRoomInfo(
    roomId: string,
    data: { category?: string; topic?: string; tags?: string[]; description?: string }
  ) {
    return prisma.roomInfo.upsert({
      where: { roomId },
      create: {
        roomId,
        category: data.category,
        topic: data.topic,
        tags: data.tags || [],
        description: data.description,
      },
      update: {
        category: data.category,
        topic: data.topic,
        tags: data.tags || [],
        description: data.description,
        updatedAt: new Date(),
      },
    });
  }

  async getRoomInfo(roomId: string) {
    return prisma.roomInfo.findUnique({
      where: { roomId },
    });
  }

  async updateRoomInfo(
    roomId: string,
    data: { category?: string; topic?: string; tags?: string[]; description?: string }
  ) {
    return prisma.roomInfo.update({
      where: { roomId },
      data: {
        ...data,
        updatedAt: new Date(),
      },
    });
  }

  async verifyRoom(roomId: string) {
    return prisma.roomInfo.update({
      where: { roomId },
      data: {
        isVerified: true,
        verifiedAt: new Date(),
      },
    });
  }

  async incrementVisits(roomId: string) {
    return prisma.roomInfo.update({
      where: { roomId },
      data: {
        totalVisits: { increment: 1 },
      },
    });
  }

  async incrementFavorites(roomId: string) {
    return prisma.roomInfo.update({
      where: { roomId },
      data: {
        totalFavorites: { increment: 1 },
      },
    });
  }

  async updateAverageRating(roomId: string, newRating: number) {
    const info = await prisma.roomInfo.findUnique({
      where: { roomId },
      select: { averageRating: true, totalFavorites: true },
    });

    if (!info) return null;

    const newAverage = (info.averageRating * (info.totalFavorites - 1) + newRating) / info.totalFavorites;

    return prisma.roomInfo.update({
      where: { roomId },
      data: { averageRating: newAverage },
    });
  }

  async searchRoomsByCategory(category: string, limit = 20) {
    return prisma.roomInfo.findMany({
      where: { category },
      take: limit,
      orderBy: { totalVisits: "desc" },
    });
  }

  async searchRoomsByTag(tag: string, limit = 20) {
    return prisma.roomInfo.findMany({
      where: {
        tags: { has: tag },
      },
      take: limit,
      orderBy: { totalVisits: "desc" },
    });
  }

  async getVerifiedRooms(limit = 20) {
    return prisma.roomInfo.findMany({
      where: { isVerified: true },
      take: limit,
      orderBy: { verifiedAt: "desc" },
    });
  }
}

const service = new RoomInfoService();

router.get("/rooms/:roomId/info", async (req: Request, res: Response) => {
  try {
    const { roomId } = req.params;
    const info = await service.getRoomInfo(roomId);

    if (!info) {
      return res.status(404).json({
        success: false,
        message: "Oda bilgisi bulunamadı",
      });
    }

    return res.status(200).json({
      success: true,
      data: info,
    });
  } catch (error) {
    console.error("getRoomInfo error:", error);
    return res.status(500).json({
      success: false,
      message: "Oda bilgisi alınamadı",
    });
  }
});

router.post("/rooms/:roomId/info", requireAuth, async (req: Request, res: Response) => {
  try {
    const { roomId } = req.params;
    const { category, topic, tags, description } = req.body;

    const info = await service.createRoomInfo(roomId, {
      category,
      topic,
      tags,
      description,
    });

    return res.status(201).json({
      success: true,
      data: info,
    });
  } catch (error) {
    console.error("createRoomInfo error:", error);
    return res.status(500).json({
      success: false,
      message: "Oda bilgisi oluşturulamadı",
    });
  }
});

router.patch("/rooms/:roomId/info", requireAuth, async (req: Request, res: Response) => {
  try {
    const { roomId } = req.params;
    const { category, topic, tags, description } = req.body;

    const info = await service.updateRoomInfo(roomId, {
      category,
      topic,
      tags,
      description,
    });

    return res.status(200).json({
      success: true,
      data: info,
    });
  } catch (error) {
    console.error("updateRoomInfo error:", error);
    return res.status(500).json({
      success: false,
      message: "Oda bilgisi güncellenemedi",
    });
  }
});

router.post("/rooms/:roomId/verify", requireAuth, async (req: Request, res: Response) => {
  try {
    const { roomId } = req.params;

    const info = await service.verifyRoom(roomId);

    return res.status(200).json({
      success: true,
      data: info,
      message: "Oda başarıyla doğrulandı",
    });
  } catch (error) {
    console.error("verifyRoom error:", error);
    return res.status(500).json({
      success: false,
      message: "Oda doğrulanamadı",
    });
  }
});

router.get("/rooms/search/category/:category", async (req: Request, res: Response) => {
  try {
    const { category } = req.params;
    const limit = parseInt(req.query.limit as string) || 20;

    const rooms = await service.searchRoomsByCategory(category, limit);

    return res.status(200).json({
      success: true,
      data: rooms,
    });
  } catch (error) {
    console.error("searchRoomsByCategory error:", error);
    return res.status(500).json({
      success: false,
      message: "Odalar aranamadı",
    });
  }
});

router.get("/rooms/search/tag/:tag", async (req: Request, res: Response) => {
  try {
    const { tag } = req.params;
    const limit = parseInt(req.query.limit as string) || 20;

    const rooms = await service.searchRoomsByTag(tag, limit);

    return res.status(200).json({
      success: true,
      data: rooms,
    });
  } catch (error) {
    console.error("searchRoomsByTag error:", error);
    return res.status(500).json({
      success: false,
      message: "Odalar aranamadı",
    });
  }
});

router.get("/rooms/verified", async (req: Request, res: Response) => {
  try {
    const limit = parseInt(req.query.limit as string) || 20;

    const rooms = await service.getVerifiedRooms(limit);

    return res.status(200).json({
      success: true,
      data: rooms,
    });
  } catch (error) {
    console.error("getVerifiedRooms error:", error);
    return res.status(500).json({
      success: false,
      message: "Doğrulanmış odalar alınamadı",
    });
  }
});

export const roomInfoRouter = router;
