import type { NextFunction, Request, Response } from "express";
import { verifyAccessToken } from "../lib/jwt";

/** Bearer varsa userId set eder; yoksa devam eder. */
export function optionalAuth(req: Request, _res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (!header?.startsWith("Bearer ")) return next();
  const token = header.slice("Bearer ".length).trim();
  if (!token) return next();
  try {
    req.userId = verifyAccessToken(token).sub;
  } catch {
    // Anonim katalog yanıtı — oturum geçersizse atamalar eklenmez.
  }
  return next();
}
