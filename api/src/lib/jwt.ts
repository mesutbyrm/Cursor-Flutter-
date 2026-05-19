import crypto from "crypto";
import jwt, { type SignOptions } from "jsonwebtoken";

const ACCESS_SECRET = () => requireEnv("JWT_ACCESS_SECRET");
const REFRESH_SECRET = () => requireEnv("JWT_REFRESH_SECRET");

function requireEnv(name: string): string {
  const v = process.env[name];
  if (!v || v.length < 16) {
    throw new Error(`${name} must be set and at least 16 characters`);
  }
  return v;
}

export type AccessJwtPayload = { sub: string; typ: "access" };

export function signAccessToken(userId: string, expiresIn: string): string {
  const payload: AccessJwtPayload = { sub: userId, typ: "access" };
  return jwt.sign(payload, ACCESS_SECRET(), { expiresIn, algorithm: "HS256" } as SignOptions);
}

export type RefreshJwtPayload = { sub: string; typ: "refresh"; jti: string };

export function signRefreshToken(userId: string, jti: string, expiresIn: string): string {
  const payload: RefreshJwtPayload = { sub: userId, typ: "refresh", jti };
  return jwt.sign(payload, REFRESH_SECRET(), { expiresIn, algorithm: "HS256" } as SignOptions);
}

export function verifyAccessToken(token: string): AccessJwtPayload {
  const decoded = jwt.verify(token, ACCESS_SECRET(), { algorithms: ["HS256"] });
  if (typeof decoded !== "object" || decoded === null) throw new Error("Invalid token");
  const o = decoded as Record<string, unknown>;
  if (o.typ !== "access" || typeof o.sub !== "string") throw new Error("Invalid access token");
  return { sub: o.sub, typ: "access" };
}

export function verifyRefreshToken(token: string): RefreshJwtPayload {
  const decoded = jwt.verify(token, REFRESH_SECRET(), { algorithms: ["HS256"] });
  if (typeof decoded !== "object" || decoded === null) throw new Error("Invalid token");
  const o = decoded as Record<string, unknown>;
  if (o.typ !== "refresh" || typeof o.sub !== "string" || typeof o.jti !== "string") {
    throw new Error("Invalid refresh token");
  }
  return { sub: o.sub, typ: "refresh", jti: o.jti };
}

export function hashToken(raw: string): string {
  return crypto.createHash("sha256").update(raw).digest("hex");
}

export function newRefreshJti(): string {
  return crypto.randomBytes(16).toString("hex");
}
