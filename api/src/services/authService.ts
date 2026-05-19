import { v4 as uuidv4 } from "uuid";
import { prisma } from "../lib/prisma";
import { AppError, ErrorCodes } from "../utils/errors";
import {
  generateResetToken,
  hashPassword,
  hashToken,
  verifyPassword,
} from "../utils/password";
import {
  signAccessToken,
  signRefreshToken,
  verifyRefreshToken,
} from "../utils/jwt";
import { serializeUser } from "../utils/userSerializer";

export async function registerUser(input: {
  email: string;
  password: string;
  name: string;
  phone?: string;
}) {
  const existing = await prisma.user.findUnique({
    where: { email: input.email.toLowerCase() },
  });
  if (existing) {
    throw new AppError(409, ErrorCodes.CONFLICT, "Bu e-posta zaten kayıtlı.");
  }

  const passwordHash = await hashPassword(input.password);
  const user = await prisma.user.create({
    data: {
      uuid: uuidv4(),
      email: input.email.toLowerCase(),
      password: passwordHash,
      name: input.name.trim(),
      phone: input.phone?.trim() || null,
    },
  });

  const tokens = await issueTokens(user.id, user.uuid, user.email);
  return { user: serializeUser(user), tokens };
}

export async function loginUser(email: string, password: string) {
  const user = await prisma.user.findUnique({
    where: { email: email.toLowerCase() },
  });
  if (!user) {
    throw new AppError(
      401,
      ErrorCodes.UNAUTHORIZED,
      "E-posta veya şifre hatalı."
    );
  }
  if (!user.isActive) {
    throw new AppError(
      403,
      ErrorCodes.FORBIDDEN,
      "Hesabınız devre dışı bırakılmış."
    );
  }

  const valid = await verifyPassword(password, user.password);
  if (!valid) {
    throw new AppError(
      401,
      ErrorCodes.UNAUTHORIZED,
      "E-posta veya şifre hatalı."
    );
  }

  const tokens = await issueTokens(user.id, user.uuid, user.email);
  return { user: serializeUser(user), tokens };
}

export async function refreshSession(refreshToken: string) {
  let payload;
  try {
    payload = verifyRefreshToken(refreshToken);
  } catch {
    throw new AppError(
      401,
      ErrorCodes.UNAUTHORIZED,
      "Geçersiz veya süresi dolmuş oturum."
    );
  }

  const user = await prisma.user.findUnique({ where: { id: payload.sub } });
  if (!user || !user.isActive) {
    throw new AppError(
      401,
      ErrorCodes.UNAUTHORIZED,
      "Geçersiz veya süresi dolmuş oturum."
    );
  }

  const tokenHash = hashToken(refreshToken);
  if (user.refreshTokenHash !== tokenHash) {
    throw new AppError(
      401,
      ErrorCodes.UNAUTHORIZED,
      "Geçersiz veya süresi dolmuş oturum."
    );
  }

  const tokens = await issueTokens(user.id, user.uuid, user.email);
  return { user: serializeUser(user), tokens };
}

export async function logoutUser(userId: number) {
  await prisma.user.update({
    where: { id: userId },
    data: { refreshTokenHash: null },
  });
}

export async function requestPasswordReset(email: string) {
  const user = await prisma.user.findUnique({
    where: { email: email.toLowerCase() },
  });
  if (!user) {
    return { resetToken: null as string | null };
  }

  const resetToken = generateResetToken();
  const expires = new Date(Date.now() + 60 * 60 * 1000);

  await prisma.user.update({
    where: { id: user.id },
    data: {
      passwordResetToken: hashToken(resetToken),
      passwordResetExpires: expires,
    },
  });

  return { resetToken };
}

export async function resetPassword(token: string, newPassword: string) {
  const tokenHash = hashToken(token);
  const user = await prisma.user.findFirst({
    where: {
      passwordResetToken: tokenHash,
      passwordResetExpires: { gt: new Date() },
    },
  });

  if (!user) {
    throw new AppError(
      400,
      ErrorCodes.VALIDATION,
      "Geçersiz veya süresi dolmuş sıfırlama bağlantısı."
    );
  }

  const passwordHash = await hashPassword(newPassword);
  await prisma.user.update({
    where: { id: user.id },
    data: {
      password: passwordHash,
      passwordResetToken: null,
      passwordResetExpires: null,
      refreshTokenHash: null,
    },
  });
}

async function issueTokens(userId: number, uuid: string, email: string) {
  const accessToken = signAccessToken({ id: userId, uuid, email });
  const refreshToken = signRefreshToken({ id: userId, uuid });

  await prisma.user.update({
    where: { id: userId },
    data: { refreshTokenHash: hashToken(refreshToken) },
  });

  return {
    accessToken,
    refreshToken,
    tokenType: "Bearer" as const,
  };
}
