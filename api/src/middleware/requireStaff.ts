import type { NextFunction, Request, Response } from "express";
import { prisma } from "../lib/prisma";
import { fail } from "../lib/response";

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
    return fail(res, 401, "UNAUTHORIZED", "Oturum gerekli");
  }
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { role: true },
  });
  if (!user || !STAFF_ROLES.has(user.role.toLowerCase())) {
    return fail(res, 403, "FORBIDDEN", "Bu alan yalnızca yetkili personel içindir");
  }
  return next();
}

export function isStaffRole(role: string | null | undefined): boolean {
  return role != null && STAFF_ROLES.has(role.toLowerCase());
}
