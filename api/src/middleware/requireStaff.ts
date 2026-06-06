import type { NextFunction, Request, Response } from "express";
import { prisma } from "../lib/prisma";
import { jsonError } from "../lib/jsonError";

const STAFF_ROLES = new Set([
  "admin",
  "yonetici",
  "moderator",
  "destek",
  "yardim",
]);

/** admin, yönetici, moderatör, destek, yardım */
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
    select: { role: true },
  });
  if (!user || !STAFF_ROLES.has(user.role.toLowerCase())) {
    return jsonError(res, 403, "Yetkiniz yok");
  }
  return next();
}

export function isStaffRole(role: string | null | undefined): boolean {
  return role != null && STAFF_ROLES.has(role.toLowerCase());
}
