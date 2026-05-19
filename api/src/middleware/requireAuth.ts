import type { NextFunction, Request, Response } from "express";
import { verifyAccessToken } from "../lib/jwt";
import { fail } from "../lib/response";

export function requireAuth(req: Request, res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith("Bearer ")) {
    return fail(res, 401, "UNAUTHORIZED", "Authorization Bearer token gerekli");
  }
  const token = header.slice("Bearer ".length).trim();
  if (!token) {
    return fail(res, 401, "UNAUTHORIZED", "Geçersiz yetkilendirme başlığı");
  }
  try {
    const payload = verifyAccessToken(token);
    req.userId = payload.sub;
    return next();
  } catch {
    return fail(res, 401, "TOKEN_INVALID", "Erişim jetonu geçersiz veya süresi dolmuş");
  }
}
