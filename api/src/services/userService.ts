import { prisma } from "../lib/prisma";
import { AppError, ErrorCodes } from "../utils/errors";
import { hashPassword, verifyPassword } from "../utils/password";
import { serializeUser } from "../utils/userSerializer";

export async function getUserById(userId: number) {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) {
    throw new AppError(404, ErrorCodes.NOT_FOUND, "Kullanıcı bulunamadı.");
  }
  return serializeUser(user);
}

export async function updateProfile(
  userId: number,
  data: { name?: string; phone?: string | null; avatarUrl?: string | null }
) {
  const user = await prisma.user.update({
    where: { id: userId },
    data: {
      ...(data.name !== undefined ? { name: data.name.trim() } : {}),
      ...(data.phone !== undefined ? { phone: data.phone } : {}),
      ...(data.avatarUrl !== undefined ? { avatarUrl: data.avatarUrl } : {}),
    },
  });
  return serializeUser(user);
}

export async function changePassword(
  userId: number,
  currentPassword: string,
  newPassword: string
) {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) {
    throw new AppError(404, ErrorCodes.NOT_FOUND, "Kullanıcı bulunamadı.");
  }

  const valid = await verifyPassword(currentPassword, user.password);
  if (!valid) {
    throw new AppError(
      400,
      ErrorCodes.VALIDATION,
      "Mevcut şifre hatalı."
    );
  }

  const passwordHash = await hashPassword(newPassword);
  await prisma.user.update({
    where: { id: userId },
    data: {
      password: passwordHash,
      refreshTokenHash: null,
    },
  });
}

export async function deleteAccount(userId: number, password: string) {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) {
    throw new AppError(404, ErrorCodes.NOT_FOUND, "Kullanıcı bulunamadı.");
  }

  const valid = await verifyPassword(password, user.password);
  if (!valid) {
    throw new AppError(
      400,
      ErrorCodes.VALIDATION,
      "Şifre hatalı."
    );
  }

  await prisma.user.delete({ where: { id: userId } });
}

export async function verifyEmail(userId: number) {
  const user = await prisma.user.update({
    where: { id: userId },
    data: { emailVerifiedAt: new Date() },
  });
  return serializeUser(user);
}
