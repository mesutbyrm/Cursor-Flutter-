import type { NextFunction, Request, Response } from "express";
import { verifyAccessToken } from "../lib/jwt";

/** Bearer varsa `req.userId` set eder; yoksa devam eder. */
export function optionalAuth(req: Request, _res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (header?.startsWith("Bearer ")) {
    const token = header.slice("Bearer ".length).trim();
    if (token) {
      try {
        const payload = verifyAccessToken(token);
        req.userId = payload.sub;
      } catch {
        /* misafir gönderim */
      }
    }
  }
  return next();
}
