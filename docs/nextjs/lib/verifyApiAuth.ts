/**
 * canlifal.com Next.js — Bearer JWT (mobil) + isteğe bağlı NextAuth oturumu.
 *
 * Mobil JWT: POST /api/auth/mobile-login ile üretilen access token.
 * Sunucu doğrulaması api/ mirror ile aynı: JWT_ACCESS_SECRET + typ=access.
 */
import type { NextRequest } from "next/server";
import jwt from "jsonwebtoken";

export type ApiAuthResult = {
  userId: string;
  source: "bearer" | "session";
};

function verifyBearerToken(request: NextRequest): string | null {
  const header = request.headers.get("authorization");
  if (!header?.startsWith("Bearer ")) return null;
  const token = header.slice(7).trim();
  if (!token) return null;

  const secret = process.env.JWT_ACCESS_SECRET?.trim();
  if (!secret || secret.length < 16) return null;

  try {
    const decoded = jwt.verify(token, secret, { algorithms: ["HS256"] });
    if (typeof decoded !== "object" || decoded === null) return null;
    const o = decoded as Record<string, unknown>;
    if (o.typ !== "access" || typeof o.sub !== "string") return null;
    return o.sub;
  } catch {
    return null;
  }
}

/**
 * NextAuth oturumu — mevcut web projenizdeki helper ile değiştirin.
 * Örnek: import { getServerSession } from "next-auth"; + authOptions
 */
async function verifyWebSession(
  _request: NextRequest,
): Promise<string | null> {
  // TODO: canlifal.com reposunda getServerSession(authOptions) kullanın.
  // const session = await getServerSession(authOptions);
  // return session?.user?.id ?? null;
  return null;
}

/** Mobil Bearer veya web oturumu — en az biri gerekli. */
export async function requireApiAuth(
  request: NextRequest,
): Promise<ApiAuthResult | null> {
  const bearerUserId = verifyBearerToken(request);
  if (bearerUserId) {
    return { userId: bearerUserId, source: "bearer" };
  }
  const sessionUserId = await verifyWebSession(request);
  if (sessionUserId) {
    return { userId: sessionUserId, source: "session" };
  }
  return null;
}

/** Bearer veya oturum — yoksa misafir (TRTC / stream için). */
export async function optionalApiAuth(
  request: NextRequest,
): Promise<ApiAuthResult | null> {
  return requireApiAuth(request);
}
