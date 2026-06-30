import type { NextFunction, Request, Response } from "express";
import { prisma } from "../lib/prisma";
import { jsonError } from "../lib/jsonError";
import { isStaffUser } from "../lib/staffAccess";

/** admin, yönetici, moderatör, destek, yardım (+ admin/yonetici kullanıcı adı) */
export async function requireStaff(
  req: Request,
  res: Response,
  next: NextFunction,
) {
  const userId = req.userId;
  if (!userId) {
    return jsonError(res, 401, "Oturum açmanız gerekiyor");
  }
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { role: true, username: true },
  });
  if (user == null || !isStaffUser(user)) {
    return jsonError(res, 403, "Yetkiniz yok");
  }
  return next();
}

export function isStaffRole(role: string | null | undefined): boolean {
  return isStaffUser({ role: role ?? "user", username: null });
}
