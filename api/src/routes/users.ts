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
    bio: z.union([z.string().max(500), z.null()]).optional(),
    avatarUrl: z.union([z.string().url().max(2048), z.string().max(500_000), z.null()]).optional(),
    username: z
      .string()
      .min(3)
      .max(32)
      .regex(/^[a-zA-Z0-9_]+$/, "Kullanıcı adı yalnızca harf, rakam ve _ içerebilir")
      .optional(),
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
  const { displayName, bio, avatarUrl, username, currentPassword, newPassword } =
    parsed.data;

  const user = await prisma.user.findUnique({ where: { id: req.userId! } });
  if (!user) {
    return fail(res, 404, "NOT_FOUND", "Kullanıcı bulunamadı");
  }

  if (username && username !== user.username) {
    const taken = await prisma.user.findUnique({ where: { username } });
    if (taken) {
      return fail(res, 409, "USERNAME_IN_USE", "Bu kullanıcı adı alınmış");
    }
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
      ...(bio !== undefined ? { bio } : {}),
      ...(avatarUrl !== undefined ? { avatarUrl } : {}),
      ...(username !== undefined ? { username } : {}),
      ...(newPassword ? { passwordHash } : {}),
    },
  });

  return ok(res, {
    id: updated.id,
    email: updated.email,
    displayName: updated.displayName,
    username: updated.username,
    bio: updated.bio ?? "",
    avatarUrl: updated.avatarUrl,
    coins: updated.coins,
    cfcBalance: updated.cfcBalance,
    followers: updated.followerCount,
    following: updated.followingCount,
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
