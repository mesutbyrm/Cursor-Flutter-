import { Router } from "express";
import { z } from "zod";
import { prisma } from "../lib/prisma";
import { hashPassword, verifyPassword } from "../lib/password";
import { fail, ok } from "../lib/response";
import { requireAuth } from "../middleware/requireAuth";

export const usersRouter = Router();

usersRouter.get("/me", requireAuth, async (req, res) => {
  const user = await prisma.user.findUnique({ where: { id: req.userId! } });
  if (!user) {
    return fail(res, 404, "NOT_FOUND", "Kullanıcı bulunamadı");
  }
  return ok(res, {
    id: user.id,
    email: user.email,
    displayName: user.displayName,
    username: user.username ?? user.email.split("@")[0],
    bio: user.bio ?? "",
    avatarUrl: user.avatarUrl ?? "https://canlifal.com/favicon.ico",
    coverUrl: user.coverUrl ?? "https://canlifal.com/apple-touch-icon.png",
    coins: user.coins,
    cfc: user.cfcBalance,
    cfcBalance: user.cfcBalance,
    role: user.role,
    followers: user.followerCount,
    following: user.followingCount,
    createdAt: user.createdAt.toISOString(),
    updatedAt: user.updatedAt.toISOString(),
  });
});

const patchMeSchema = z
  .object({
    displayName: z.union([z.string().min(1).max(120), z.null()]).optional(),
    currentPassword: z.string().optional(),
    newPassword: z.string().min(8, "Yeni şifre en az 8 karakter olmalı").optional(),
  })
  .superRefine((val, ctx) => {
    if (val.newPassword && (!val.currentPassword || val.currentPassword.length === 0)) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: "Şifre değişimi için mevcut şifre gerekli",
        path: ["currentPassword"],
      });
    }
  });

usersRouter.patch("/me", requireAuth, async (req, res) => {
  const parsed = patchMeSchema.safeParse(req.body);
  if (!parsed.success) {
    return fail(res, 400, "VALIDATION_ERROR", "Geçersiz istek gövdesi", parsed.error.flatten());
  }
  const { displayName, currentPassword, newPassword } = parsed.data;

  const user = await prisma.user.findUnique({ where: { id: req.userId! } });
  if (!user) {
    return fail(res, 404, "NOT_FOUND", "Kullanıcı bulunamadı");
  }

  let passwordHash = user.passwordHash;
  if (newPassword) {
    const valid = await verifyPassword(currentPassword!, user.passwordHash);
    if (!valid) {
      return fail(res, 401, "INVALID_PASSWORD", "Mevcut şifre hatalı");
    }
    passwordHash = await hashPassword(newPassword);
  }

  const updated = await prisma.user.update({
    where: { id: user.id },
    data: {
      ...(displayName !== undefined ? { displayName } : {}),
      ...(newPassword ? { passwordHash } : {}),
    },
  });

  return ok(res, {
    id: updated.id,
    email: updated.email,
    displayName: updated.displayName,
    createdAt: updated.createdAt.toISOString(),
    updatedAt: updated.updatedAt.toISOString(),
  });
});

usersRouter.delete("/me", requireAuth, async (req, res) => {
  const bodySchema = z.object({
    password: z.string().min(1, "Hesabı silmek için şifre gerekli"),
  });
  const parsed = bodySchema.safeParse(req.body);
  if (!parsed.success) {
    return fail(res, 400, "VALIDATION_ERROR", "Geçersiz istek gövdesi", parsed.error.flatten());
  }
  const user = await prisma.user.findUnique({ where: { id: req.userId! } });
  if (!user) {
    return fail(res, 404, "NOT_FOUND", "Kullanıcı bulunamadı");
  }
  const valid = await verifyPassword(parsed.data.password, user.passwordHash);
  if (!valid) {
    return fail(res, 401, "INVALID_PASSWORD", "Şifre hatalı");
  }
  await prisma.user.delete({ where: { id: user.id } });
  return ok(res, { deleted: true });
});
