import { Router } from "express";
import { z } from "zod";
import { prisma } from "../lib/prisma";
import {
  normalizeUsername,
  oauthPlaceholderPassword,
  publicUserPayload,
} from "../lib/auth_user";
import { verifyGoogleIdToken } from "../lib/google_auth";
import { exchangeTikTokCode, fetchTikTokUser } from "../lib/tiktok_auth";
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
  displayName: z.string().min(1).max(120),
  username: z.string().min(3).max(32).regex(/^[a-zA-Z0-9_]+$/),
  phone: z.string().max(32).optional(),
  birthDate: z.string().optional(),
  birthTime: z.string().max(8).optional(),
  language: z.string().min(2).max(10).default("tr"),
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

const googleSchema = z.object({
  idToken: z.string().min(20),
});

const tiktokSchema = z.object({
  code: z.string().min(4),
  redirectUri: z.string().url(),
});

const refreshSchema = z.object({
  refreshToken: z.string().min(10),
});

const logoutSchema = z.object({
  refreshToken: z.string().min(10).optional(),
});

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

function parseDurationToMs(input: string): number | null {
  const m = /^(\d+)(ms|s|m|h|d)$/.exec(input.trim());
  if (!m) return null;
  const n = Number(m[1]);
  const u = m[2];
  const mult: Record<string, number> = {
    ms: 1,
    s: 1000,
    m: 60_000,
    h: 3_600_000,
    d: 86_400_000,
  };
  return n * (mult[u] ?? 0);
}

function parseBirthDate(raw?: string): Date | null {
  if (!raw?.trim()) return null;
  const d = new Date(raw.trim());
  return Number.isNaN(d.getTime()) ? null : d;
}

async function authResponse(user: { id: string }, status = 200) {
  const full = await prisma.user.findUniqueOrThrow({ where: { id: user.id } });
  const tokens = await issueTokens(user.id);
  return {
    status,
    body: {
      user: publicUserPayload(full),
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      tokenType: "Bearer",
      expiresIn: tokens.expiresIn,
    },
  };
}

export const authRouter = Router();

authRouter.get("/me", requireAuth, async (req, res) => {
  const user = await prisma.user.findUnique({ where: { id: req.userId! } });
  if (!user) return fail(res, 404, "NOT_FOUND", "Kullanıcı bulunamadı");
  return ok(res, { user: publicUserPayload(user) });
});

authRouter.post("/register", async (req, res) => {
  const parsed = registerSchema.safeParse(req.body);
  if (!parsed.success) {
    return fail(res, 400, "VALIDATION_ERROR", "Geçersiz istek", parsed.error.flatten());
  }
  const data = parsed.data;
  const email = data.email.toLowerCase();
  const username = normalizeUsername(data.username, email);

  const existingEmail = await prisma.user.findUnique({ where: { email } });
  if (existingEmail) {
    return fail(res, 409, "EMAIL_IN_USE", "Bu e-posta zaten kayıtlı");
  }
  const existingUser = await prisma.user.findUnique({ where: { username } });
  if (existingUser) {
    return fail(res, 409, "USERNAME_IN_USE", "Bu kullanıcı adı alınmış");
  }

  const user = await prisma.user.create({
    data: {
      email,
      passwordHash: await hashPassword(data.password),
      displayName: data.displayName.trim(),
      username,
      phone: data.phone?.trim() || null,
      birthDate: parseBirthDate(data.birthDate),
      birthTime: data.birthTime?.trim() || null,
      language: data.language,
    },
  });

  const out = await authResponse(user, 201);
  return res.status(out.status).json({ success: true, data: out.body });
});

authRouter.post("/login", async (req, res) => {
  const parsed = loginSchema.safeParse(req.body);
  if (!parsed.success) {
    return fail(res, 400, "VALIDATION_ERROR", "Geçersiz istek", parsed.error.flatten());
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
  const out = await authResponse(user);
  return ok(res, out.body);
});

/** Native Google — ID token → SQL kullanıcı + JWT (WebView yok). */
authRouter.post("/google", async (req, res) => {
  const parsed = googleSchema.safeParse(req.body);
  if (!parsed.success) {
    return fail(res, 400, "VALIDATION_ERROR", "Geçersiz Google token");
  }

  const payload = await verifyGoogleIdToken(parsed.data.idToken);
  if (!payload?.sub) {
    return fail(res, 401, "GOOGLE_INVALID", "Google oturumu doğrulanamadı");
  }

  const email =
    payload.email?.toLowerCase() ??
    `google_${payload.sub}@canlifal.oauth`;

  let user = await prisma.user.findFirst({
    where: { OR: [{ googleId: payload.sub }, { email }] },
  });

  if (!user) {
    user = await prisma.user.create({
      data: {
        email,
        googleId: payload.sub,
        passwordHash: await oauthPlaceholderPassword(),
        displayName: payload.name?.slice(0, 120) ?? "Canlifal Üyesi",
        username: normalizeUsername(
          payload.name ?? email.split("@")[0],
          email,
        ),
        avatarUrl: payload.picture ?? null,
        language: "tr",
      },
    });
  } else if (!user.googleId) {
    user = await prisma.user.update({
      where: { id: user.id },
      data: {
        googleId: payload.sub,
        avatarUrl: user.avatarUrl ?? payload.picture ?? null,
      },
    });
  }

  const out = await authResponse(user);
  return ok(res, out.body);
});

/** TikTok — yalnızca mobil; authorization code ile. */
authRouter.post("/tiktok", async (req, res) => {
  const parsed = tiktokSchema.safeParse(req.body);
  if (!parsed.success) {
    return fail(res, 400, "VALIDATION_ERROR", "Geçersiz TikTok isteği");
  }

  const exchanged = await exchangeTikTokCode(
    parsed.data.code,
    parsed.data.redirectUri,
  );
  if (!exchanged) {
    return fail(res, 401, "TIKTOK_INVALID", "TikTok oturumu doğrulanamadı");
  }

  const profile = await fetchTikTokUser(exchanged.accessToken);
  const openId = profile?.openId ?? exchanged.openId;

  let user = await prisma.user.findUnique({ where: { tiktokId: openId } });

  if (!user) {
    const email = `tiktok_${openId}@canlifal.oauth`;
    user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
      user = await prisma.user.create({
        data: {
          email,
          tiktokId: openId,
          passwordHash: await oauthPlaceholderPassword(),
          displayName: profile?.displayName?.slice(0, 120) ?? "TikTok Üyesi",
          username: normalizeUsername(
            profile?.displayName ?? openId,
            email,
          ),
          avatarUrl: profile?.avatarUrl ?? null,
          language: "tr",
        },
      });
    } else {
      user = await prisma.user.update({
        where: { id: user.id },
        data: { tiktokId: openId },
      });
    }
  }

  const out = await authResponse(user);
  return ok(res, out.body);
});

authRouter.post("/refresh", async (req, res) => {
  const parsed = refreshSchema.safeParse(req.body);
  if (!parsed.success) {
    return fail(res, 400, "VALIDATION_ERROR", "Geçersiz istek");
  }
  const { refreshToken } = parsed.data;
  let payload;
  try {
    payload = verifyRefreshToken(refreshToken);
  } catch {
    return fail(res, 401, "REFRESH_INVALID", "Yenileme jetonu geçersiz");
  }
  const tokenHash = hashToken(refreshToken);
  const stored = await prisma.refreshToken.findUnique({ where: { tokenHash } });
  if (!stored || stored.expiresAt < new Date()) {
    return fail(res, 401, "REFRESH_REVOKED", "Oturum geçersiz");
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
    return fail(res, 400, "VALIDATION_ERROR", "Geçersiz istek");
  }
  const rt = parsed.data.refreshToken;
  if (rt) {
    const tokenHash = hashToken(rt);
    await prisma.refreshToken.deleteMany({ where: { tokenHash } });
  }
  return ok(res, { loggedOut: true });
});

authRouter.post("/logout-all", requireAuth, async (req, res) => {
  await prisma.refreshToken.deleteMany({ where: { userId: req.userId! } });
  return ok(res, { loggedOutAll: true });
});
