import jwt from "jsonwebtoken";
import { env } from "../config/env";

export interface AccessTokenPayload {
  sub: number;
  uuid: string;
  email: string;
  type: "access";
}

export interface RefreshTokenPayload {
  sub: number;
  uuid: string;
  type: "refresh";
}

export function signAccessToken(user: {
  id: number;
  uuid: string;
  email: string;
}): string {
  const payload: AccessTokenPayload = {
    sub: user.id,
    uuid: user.uuid,
    email: user.email,
    type: "access",
  };
  return jwt.sign(payload, env.jwt.accessSecret, {
    expiresIn: env.jwt.accessExpiresIn,
  } as jwt.SignOptions);
}

export function signRefreshToken(user: { id: number; uuid: string }): string {
  const payload: RefreshTokenPayload = {
    sub: user.id,
    uuid: user.uuid,
    type: "refresh",
  };
  return jwt.sign(payload, env.jwt.refreshSecret, {
    expiresIn: env.jwt.refreshExpiresIn,
  } as jwt.SignOptions);
}

export function verifyAccessToken(token: string): AccessTokenPayload {
  const raw = jwt.verify(token, env.jwt.accessSecret);
  if (typeof raw === "string") {
    throw new Error("Invalid token");
  }
  const payload = raw as unknown as AccessTokenPayload;
  if (payload.type !== "access") {
    throw new Error("Invalid token type");
  }
  return payload;
}

export function verifyRefreshToken(token: string): RefreshTokenPayload {
  const raw = jwt.verify(token, env.jwt.refreshSecret);
  if (typeof raw === "string") {
    throw new Error("Invalid token");
  }
  const payload = raw as unknown as RefreshTokenPayload;
  if (payload.type !== "refresh") {
    throw new Error("Invalid token type");
  }
  return payload;
}
