import type { Request, Response, NextFunction } from "express";
import { kvIncr } from "./client";
import { RedisKeys } from "./keys";

export type RateLimitScope = "login" | "message" | "gift" | "api";

const LIMITS: Record<RateLimitScope, { windowSec: number; max: number }> = {
  login: { windowSec: 60, max: 10 },
  message: { windowSec: 60, max: 120 },
  gift: { windowSec: 60, max: 60 },
  api: { windowSec: 60, max: 300 },
};

function keyFor(scope: RateLimitScope, req: Request): string {
  const userId = req.userId;
  const ip =
    (req.headers["x-forwarded-for"] as string)?.split(",")[0]?.trim() ??
    req.socket.remoteAddress ??
    "unknown";
  const base = userId ? `u:${userId}` : `ip:${ip}`;
  switch (scope) {
    case "login":
      return RedisKeys.rate.login(base);
    case "message":
      return RedisKeys.rate.message(base);
    case "gift":
      return RedisKeys.rate.gift(base);
    case "api":
      return RedisKeys.rate.api(base);
  }
}

export async function checkRateLimit(
  scope: RateLimitScope,
  req: Request,
): Promise<{ allowed: boolean; remaining: number }> {
  const { windowSec, max } = LIMITS[scope];
  const key = keyFor(scope, req);
  const count = await kvIncr(key, windowSec);
  return { allowed: count <= max, remaining: Math.max(0, max - count) };
}

export function rateLimitMiddleware(scope: RateLimitScope) {
  return async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { allowed, remaining } = await checkRateLimit(scope, req);
      res.setHeader("X-RateLimit-Remaining", String(remaining));
      if (!allowed) {
        return res.status(429).json({
          success: false,
          error: "RATE_LIMIT",
          message: "Çok fazla istek. Lütfen kısa süre sonra tekrar deneyin.",
        });
      }
      return next();
    } catch {
      return next();
    }
  };
}
