import { Router } from "express";
import { z } from "zod";
import { prisma } from "../lib/prisma";
import { hashPassword, verifyPassword } from "../lib/password";
import {
  hashToken,
  newRefreshJti,
  signAccessToken,
  signRefreshToken,
  verifyRefreshToken,
} from "../lib/jwt";
import { fail, ok } from "../lib/response";
import { requireAuth } from "../middleware/requireAuth";

const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8, "Şifre en az 8 karakter olmalı"),
  displayName: z.string().min(1).max(120).optional(),
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

const refreshSchema = z.object({
  refreshToken: z.string().min(10),
});

const logoutSchema = z.object({
  refreshToken: z.string().min(10).optional(),
});

function publicUser(u: { id: string; email: string; displayName: string | null; createdAt: Date }) {
  return {
    id: u.id,
    email: u.email,
    displayName: u.displayName,
    createdAt: u.createdAt.toISOString(),
  };
}

async function issueTokens(userId: string) {
  const accessExpiresIn = process.env.JWT_ACCESS_EXPIRES_IN ?? "15m";
  const refreshExpiresIn = process.env.JWT_REFRESH_EXPIRES_IN ?? "30d";
  const jti = newRefreshJti();
  const accessToken = signAccessToken(userId, accessExpiresIn);
  const refreshToken = signRefreshToken(userId, jti, refreshExpiresIn);
  const tokenHash = hashToken(refreshToken);
  const refreshMs = parseDurationToMs(refreshExpiresIn) ?? 30 * 24 * 60 * 60 * 1000;
  const expiresAt = new Date(Date.now() + refreshMs);

  await prisma.refreshToken.create({
    data: { userId, tokenHash, expiresAt },
  });

  return { accessToken, refreshToken, expiresIn: accessExpiresIn };
}

/** Basit süre ifadesi: 15m, 7d, 24h — yalnızca refresh TTL hesabı için */
function parseDurationToMs(input: string): number | null {
  const m = /^(\d+)(ms|s|m|h|d)$/.exec(input.trim());
  if (!m) return null;
  const n = Number(m[1]);
  const u = m[2];
  const mult: Record<string, number> = { ms: 1, s: 1000, m: 60_000, h: 3_600_000, d: 86_400_000 };
  return n * (mult[u] ?? 0);
}

export const authRouter = Router();

authRouter.post("/register", async (req, res) => {
  const parsed = registerSchema.safeParse(req.body);
  if (!parsed.success) {
    return fail(res, 400, "VALIDATION_ERROR", "Geçersiz istek gövdesi", parsed.error.flatten());
  }
  const { email, password, displayName } = parsed.data;
  const existing = await prisma.user.findUnique({ where: { email: email.toLowerCase() } });
  if (existing) {
    return fail(res, 409, "EMAIL_IN_USE", "Bu e-posta adresi zaten kayıtlı");
  }
  const passwordHash = await hashPassword(password);
  const user = await prisma.user.create({
    data: {
      email: email.toLowerCase(),
      passwordHash,
      displayName: displayName ?? null,
    },
  });
  const tokens = await issueTokens(user.id);
  return ok(
    res,
    {
      user: publicUser(user),
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      tokenType: "Bearer",
      expiresIn: tokens.expiresIn,
    },
    201,
  );
});

authRouter.post("/login", async (req, res) => {
  const parsed = loginSchema.safeParse(req.body);
  if (!parsed.success) {
    return fail(res, 400, "VALIDATION_ERROR", "Geçersiz istek gövdesi", parsed.error.flatten());
  }
  const { email, password } = parsed.data;
  const user = await prisma.user.findUnique({ where: { email: email.toLowerCase() } });
  if (!user) {
    return fail(res, 401, "INVALID_CREDENTIALS", "E-posta veya şifre hatalı");
  }
  const valid = await verifyPassword(password, user.passwordHash);
  if (!valid) {
    return fail(res, 401, "INVALID_CREDENTIALS", "E-posta veya şifre hatalı");
  }
  const tokens = await issueTokens(user.id);
  return ok(res, {
    user: publicUser(user),
    accessToken: tokens.accessToken,
    refreshToken: tokens.refreshToken,
    tokenType: "Bearer",
    expiresIn: tokens.expiresIn,
  });
});

authRouter.post("/refresh", async (req, res) => {
  const parsed = refreshSchema.safeParse(req.body);
  if (!parsed.success) {
    return fail(res, 400, "VALIDATION_ERROR", "Geçersiz istek gövdesi", parsed.error.flatten());
  }
  const { refreshToken } = parsed.data;
  let payload;
  try {
    payload = verifyRefreshToken(refreshToken);
  } catch {
    return fail(res, 401, "REFRESH_INVALID", "Yenileme jetonu geçersiz veya süresi dolmuş");
  }
  const tokenHash = hashToken(refreshToken);
  const stored = await prisma.refreshToken.findUnique({ where: { tokenHash } });
  if (!stored || stored.expiresAt < new Date()) {
    return fail(res, 401, "REFRESH_REVOKED", "Oturum geçersiz; tekrar giriş yapın");
  }
  if (stored.userId !== payload.sub) {
    return fail(res, 401, "REFRESH_INVALID", "Yenileme jetonu geçersiz");
  }

  await prisma.refreshToken.delete({ where: { id: stored.id } });
  const tokens = await issueTokens(stored.userId);
  return ok(res, {
    accessToken: tokens.accessToken,
    refreshToken: tokens.refreshToken,
    tokenType: "Bearer",
    expiresIn: tokens.expiresIn,
  });
});

authRouter.post("/logout", async (req, res) => {
  const parsed = logoutSchema.safeParse(req.body ?? {});
  if (!parsed.success) {
    return fail(res, 400, "VALIDATION_ERROR", "Geçersiz istek gövdesi", parsed.error.flatten());
  }
  const rt = parsed.data.refreshToken;
  if (rt) {
    const tokenHash = hashToken(rt);
    await prisma.refreshToken.deleteMany({ where: { tokenHash } });
  }
  return ok(res, { loggedOut: true });
});

authRouter.post("/logout-all", requireAuth, async (req, res) => {
  const userId = req.userId!;
  await prisma.refreshToken.deleteMany({ where: { userId } });
  return ok(res, { loggedOutAll: true });
});
