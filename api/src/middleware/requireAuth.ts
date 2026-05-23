import type { NextFunction, Request, Response } from "express";
import { verifyAccessToken } from "../lib/jwt";
import { jsonError } from "../lib/jsonError";

export function requireAuth(req: Request, res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith("Bearer ")) {
    return jsonError(res, 401, "Oturum açmanız gerekiyor");
  }
  const token = header.slice("Bearer ".length).trim();
  if (!token) {
    return jsonError(res, 401, "Oturum açmanız gerekiyor");
  }
  try {
    const payload = verifyAccessToken(token);
    req.userId = payload.sub;
    return next();
  } catch {
    return jsonError(res, 401, "Oturum açmanız gerekiyor");
  }
}
