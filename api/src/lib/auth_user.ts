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

export function publicUserPayload(u: User) {
  return {
    id: u.id,
    email: u.email,
    displayName: u.displayName,
    username: u.username,
    avatarUrl: u.avatarUrl,
    bio: u.bio,
    phone: u.phone,
    birthDate: u.birthDate?.toISOString().slice(0, 10) ?? null,
    birthTime: u.birthTime,
    language: u.language,
    role: u.role,
    coins: u.coins,
    cfcBalance: u.cfcBalance,
    followerCount: u.followerCount,
    followingCount: u.followingCount,
    createdAt: u.createdAt.toISOString(),
  };
}
