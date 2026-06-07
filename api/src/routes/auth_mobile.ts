import { Router } from "express";
import { z } from "zod";
import { prisma } from "../lib/prisma";
import {
  normalizeUsername,
  oauthPlaceholderPassword,
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
import { jsonError } from "../lib/jsonError";
import { mobileAuthBody } from "../lib/authMobile";

const mobileRegisterSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  name: z.string().min(1).max(120),
  username: z.string().min(3).max(32).regex(/^[a-zA-Z0-9_]+$/),
  birthDate: z.string().min(4),
  birthTime: z.string().min(4),
  referralCode: z.string().max(32).optional(),
  preferredLanguage: z.string().min(2).max(10).optional(),
});

const mobileLoginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

const googleSchema = z.object({
  idToken: z.string().min(20),
  referralCode: z.string().max(32).optional(),
});

const tiktokMobileSchema = z.object({
  code: z.string().min(4),
  redirectUri: z.string().optional(),
  referralCode: z.string().max(32).optional(),
});

const refreshSchema = z.object({
  refreshToken: z.string().min(10),
});

const forgotSchema = z.object({
  email: z.string().email(),
});

function parseBirthDate(raw?: string): Date | null {
  if (!raw?.trim()) return null;
  const d = new Date(raw.trim());
  return Number.isNaN(d.getTime()) ? null : d;
}

function parseDurationToMs(input: string): number | null {
  const m = /^(\d+)(ms|s|m|h|d)$/.exec(input.trim());
  if (!m) return null;
  const n = Number(m[1]);
  const mult: Record<string, number> = {
    ms: 1,
    s: 1000,
    m: 60_000,
    h: 3_600_000,
    d: 86_400_000,
  };
  return n * (mult[m[2]] ?? 0);
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

export const authMobileRouter = Router();

authMobileRouter.post("/mobile-register", async (req, res) => {
  const parsed = mobileRegisterSchema.safeParse(req.body);
  if (!parsed.success) {
    return jsonError(
      res,
      400,
      "Zorunlu alanlar: email, password, name, username, birthDate, birthTime",
    );
  }
  const data = parsed.data;
  const email = data.email.toLowerCase();
  const username = normalizeUsername(data.username, email);

  if (await prisma.user.findUnique({ where: { email } })) {
    return jsonError(res, 400, "Bu e-posta adresi zaten kayıtlı");
  }
  if (await prisma.user.findUnique({ where: { username } })) {
    return jsonError(res, 400, "Bu kullanıcı adı zaten alınmış");
  }

  const user = await prisma.user.create({
    data: {
      email,
      passwordHash: await hashPassword(data.password),
      displayName: data.name.trim(),
      username,
      birthDate: parseBirthDate(data.birthDate),
      birthTime: data.birthTime.trim(),
      language: data.preferredLanguage ?? "tr",
      coins: 500,
    },
  });

  const tokens = await issueTokens(user.id);
  return res.status(201).json(mobileAuthBody(user, tokens));
});

authMobileRouter.post("/mobile-login", async (req, res) => {
  const parsed = mobileLoginSchema.safeParse(req.body);
  if (!parsed.success) {
    return jsonError(res, 400, "E-posta ve şifre gereklidir");
  }
  const user = await prisma.user.findUnique({
    where: { email: parsed.data.email.toLowerCase() },
  });
  if (!user || !(await verifyPassword(parsed.data.password, user.passwordHash))) {
    return jsonError(res, 401, "E-posta veya şifre hatalı");
  }
  const tokens = await issueTokens(user.id);
  return res.status(200).json(mobileAuthBody(user, tokens));
});

authMobileRouter.post("/mobile-google", async (req, res) => {
  const parsed = googleSchema.safeParse(req.body);
  if (!parsed.success) {
    return jsonError(res, 401, "Geçersiz Google token");
  }
  const payload = await verifyGoogleIdToken(parsed.data.idToken);
  if (!payload?.sub) {
    return jsonError(res, 401, "Geçersiz Google token");
  }

  const email =
    payload.email?.toLowerCase() ?? `google_${payload.sub}@canlifal.oauth`;

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
        username: normalizeUsername(payload.name ?? email.split("@")[0], email),
        avatarUrl: payload.picture ?? null,
        language: "tr",
        coins: 500,
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

  const tokens = await issueTokens(user.id);
  return res.status(200).json(mobileAuthBody(user, tokens));
});

authMobileRouter.post("/mobile-tiktok", async (req, res) => {
  const parsed = tiktokMobileSchema.safeParse(req.body);
  if (!parsed.success) {
    return jsonError(res, 400, "Geçersiz TikTok isteği");
  }
  const redirect =
    parsed.data.redirectUri?.trim() ||
    process.env.TIKTOK_REDIRECT_URI ||
    "canlifal://tiktok-auth";

  const exchanged = await exchangeTikTokCode(parsed.data.code, redirect);
  if (!exchanged) {
    return jsonError(res, 401, "TikTok oturumu doğrulanamadı");
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
          username: normalizeUsername(profile?.displayName ?? openId, email),
          avatarUrl: profile?.avatarUrl ?? null,
          language: "tr",
          coins: 500,
        },
      });
    } else {
      user = await prisma.user.update({
        where: { id: user.id },
        data: { tiktokId: openId },
      });
    }
  }

  const tokens = await issueTokens(user.id);
  return res.status(200).json(mobileAuthBody(user, tokens));
});

authMobileRouter.post("/mobile-refresh", async (req, res) => {
  const parsed = refreshSchema.safeParse(req.body);
  if (!parsed.success) {
    return jsonError(res, 400, "Geçersiz istek");
  }
  let payload;
  try {
    payload = verifyRefreshToken(parsed.data.refreshToken);
  } catch {
    return jsonError(res, 401, "Yenileme jetonu geçersiz");
  }
  const tokenHash = hashToken(parsed.data.refreshToken);
  const stored = await prisma.refreshToken.findUnique({ where: { tokenHash } });
  if (!stored || stored.expiresAt < new Date() || stored.userId !== payload.sub) {
    return jsonError(res, 401, "Oturum geçersiz");
  }
  await prisma.refreshToken.delete({ where: { id: stored.id } });
  const tokens = await issueTokens(stored.userId);
  return res.status(200).json({
    accessToken: tokens.accessToken,
    refreshToken: tokens.refreshToken,
    tokenType: "Bearer",
    expiresIn: tokens.expiresIn,
  });
});

authMobileRouter.post("/forgot-password", async (req, res) => {
  const parsed = forgotSchema.safeParse(req.body);
  if (!parsed.success) {
    return jsonError(res, 400, "Geçersiz e-posta");
  }
  // Prod: e-posta OTP gönderimi. Mirror: her zaman başarılı (enumeration önleme).
  return res.status(200).json({ success: true });
});
