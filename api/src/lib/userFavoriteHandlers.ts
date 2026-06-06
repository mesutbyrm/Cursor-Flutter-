import type { Request, Response } from "express";
import { z } from "zod";
import { prisma } from "./prisma";
import { fail } from "./response";

const createFavoriteSchema = z.object({
  targetType: z.enum(["user", "post", "fortune", "content", "room"]),
  targetId: z.string().min(1).max(128),
  title: z.string().max(200).optional(),
  url: z.string().max(2048).optional(),
  imageUrl: z.string().max(2048).optional(),
});

function favoritePayload(row: {
  id: string;
  targetType: string;
  targetId: string;
  title: string | null;
  url: string | null;
  imageUrl: string | null;
  createdAt: Date;
}) {
  return {
    id: row.id,
    targetType: row.targetType,
    targetId: row.targetId,
    title: row.title ?? undefined,
    url: row.url ?? undefined,
    imageUrl: row.imageUrl ?? undefined,
    createdAt: row.createdAt.toISOString(),
  };
}

export async function listUserFavorites(req: Request, res: Response) {
  const rows = await prisma.userFavorite.findMany({
    where: { userId: req.userId! },
    orderBy: { createdAt: "desc" },
    take: 100,
  });
  return res.status(200).json(rows.map(favoritePayload));
}

export async function createUserFavorite(req: Request, res: Response) {
  const parsed = createFavoriteSchema.safeParse(req.body);
  if (!parsed.success) {
    return fail(res, 400, "VALIDATION_ERROR", "Geçersiz favori");
  }
  const d = parsed.data;
  const created = await prisma.userFavorite.upsert({
    where: {
      userId_targetType_targetId: {
        userId: req.userId!,
        targetType: d.targetType,
        targetId: d.targetId,
      },
    },
    create: {
      userId: req.userId!,
      targetType: d.targetType,
      targetId: d.targetId,
      title: d.title,
      url: d.url,
      imageUrl: d.imageUrl,
    },
    update: {
      title: d.title,
      url: d.url,
      imageUrl: d.imageUrl,
    },
  });
  return res.status(201).json(favoritePayload(created));
}

export async function deleteUserFavorite(req: Request, res: Response) {
  const row = await prisma.userFavorite.findFirst({
    where: { id: req.params.id, userId: req.userId! },
  });
  if (!row) {
    return fail(res, 404, "NOT_FOUND", "Favori bulunamadı");
  }
  await prisma.userFavorite.delete({ where: { id: row.id } });
  return res.status(200).json({ deleted: true });
}
