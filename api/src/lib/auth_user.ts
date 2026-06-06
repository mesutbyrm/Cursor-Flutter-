import { randomBytes } from "node:crypto";
import type { User } from "@prisma/client";
import { hashPassword } from "./password";

export function normalizeUsername(raw: string, fallbackEmail: string): string {
  const base = raw
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9_]/g, "_")
    .replace(/_+/g, "_")
    .replace(/^_|_$/g, "");
  if (base.length >= 3) return base.slice(0, 32);
  const local = fallbackEmail.split("@")[0] ?? "user";
  return `${local.replace(/[^a-z0-9]/g, "")}_${randomBytes(2).toString("hex")}`.slice(
    0,
    32,
  );
}

export async function oauthPlaceholderPassword(): Promise<string> {
  return hashPassword(randomBytes(32).toString("hex"));
}

/** Tam kullanıcı veya Prisma `select` ile kısmi satır — takip listeleri dahil. */
export type PublicUserSource = Pick<
  User,
  "id" | "displayName" | "username" | "avatarUrl" | "bio" | "followerCount"
> &
  Partial<
    Pick<
      User,
      | "email"
      | "phone"
      | "birthDate"
      | "birthTime"
      | "language"
      | "role"
      | "coins"
      | "cfcBalance"
      | "followingCount"
      | "createdAt"
    >
  >;

export function publicUserPayload(u: PublicUserSource) {
  return {
    id: u.id,
    email: u.email ?? null,
    displayName: u.displayName,
    username: u.username,
    avatarUrl: u.avatarUrl,
    bio: u.bio,
    phone: u.phone ?? null,
    birthDate: u.birthDate?.toISOString().slice(0, 10) ?? null,
    birthTime: u.birthTime ?? null,
    language: u.language ?? null,
    role: u.role ?? "user",
    coins: u.coins ?? 0,
    cfcBalance: u.cfcBalance ?? 0,
    followerCount: u.followerCount,
    followingCount: u.followingCount ?? 0,
    createdAt: u.createdAt?.toISOString() ?? null,
  };
}
