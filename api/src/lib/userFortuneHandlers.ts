import type { Request, Response } from "express";
import { z } from "zod";
import { prisma } from "./prisma";
import { fail } from "./response";

const listQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(50).default(10),
});

const createFortuneSchema = z.object({
  type: z.string().min(1).max(64),
  slug: z.string().max(64).optional(),
  question: z.string().max(2000).optional(),
  answer: z.string().max(8000).optional(),
  summary: z.string().max(800).optional(),
  detail: z.string().max(4000).optional(),
  luckyNumber: z.coerce.number().int().min(0).max(999).optional(),
  luckyColor: z.string().max(64).optional(),
});

function fortunePayload(row: {
  id: string;
  type: string;
  slug: string | null;
  question: string | null;
  answer: string | null;
  summary: string | null;
  detail: string | null;
  luckyNumber: number | null;
  luckyColor: string | null;
  createdAt: Date;
}) {
  return {
    id: row.id,
    type: row.type,
    slug: row.slug ?? undefined,
    question: row.question ?? undefined,
    answer: row.answer ?? row.summary ?? undefined,
    summary: row.summary ?? undefined,
    detail: row.detail ?? undefined,
    luckyNumber: row.luckyNumber ?? undefined,
    luckyColor: row.luckyColor ?? undefined,
    createdAt: row.createdAt.toISOString(),
  };
}

export async function listUserFortunes(req: Request, res: Response) {
  const parsed = listQuerySchema.safeParse(req.query);
  if (!parsed.success) {
    return fail(res, 400, "VALIDATION_ERROR", "Geçersiz sayfalama");
  }
  const { page, limit } = parsed.data;
  const userId = req.userId!;

  const [total, rows] = await Promise.all([
    prisma.userFortune.count({ where: { userId } }),
    prisma.userFortune.findMany({
      where: { userId },
      orderBy: { createdAt: "desc" },
      skip: (page - 1) * limit,
      take: limit,
    }),
  ]);

  return res.status(200).json({
    fortunes: rows.map(fortunePayload),
    total,
    page,
    limit,
  });
}

export async function getUserFortune(req: Request, res: Response) {
  const row = await prisma.userFortune.findFirst({
    where: { id: req.params.fortuneId, userId: req.userId! },
  });
  if (!row) {
    return fail(res, 404, "NOT_FOUND", "Fal kaydı bulunamadı");
  }
  return res.status(200).json(fortunePayload(row));
}

export async function createUserFortune(req: Request, res: Response) {
  const parsed = createFortuneSchema.safeParse(req.body);
  if (!parsed.success) {
    return fail(res, 400, "VALIDATION_ERROR", "Geçersiz fal kaydı");
  }
  const d = parsed.data;
  const created = await prisma.userFortune.create({
    data: {
      userId: req.userId!,
      type: d.type,
      slug: d.slug ?? d.type,
      question: d.question,
      answer: d.answer ?? d.summary,
      summary: d.summary,
      detail: d.detail,
      luckyNumber: d.luckyNumber,
      luckyColor: d.luckyColor,
    },
  });
  return res.status(201).json(fortunePayload(created));
}
