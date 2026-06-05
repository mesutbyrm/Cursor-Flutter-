import type { User } from "@prisma/client";

/** canlifal.com mobil JWT yanıtı — düz JSON (`{ accessToken, user }`). */
export function mobileUserPayload(user: User) {
  return {
    id: user.id,
    email: user.email,
    name: user.displayName ?? user.username ?? user.email.split("@")[0],
    username: user.username ?? user.email.split("@")[0],
    role: user.role,
    image: user.avatarUrl,
    credits: user.coins,
    jetonBalance: user.coins,
    cfcBalance: user.cfcBalance,
    membership: user.membership === "basic" ? null : user.membership,
    membershipExpiresAt: user.membershipExpiresAt?.toISOString() ?? null,
    preferredLanguage: user.language,
    phone: user.phone,
    birthDate: user.birthDate?.toISOString() ?? null,
    birthTime: user.birthTime,
    bio: user.bio,
    referralCode: user.id.slice(-8).toUpperCase(),
  };
}

export function mobileAuthBody(
  user: User,
  tokens: {
    accessToken: string;
    refreshToken: string;
    expiresIn?: string;
  },
) {
  return {
    accessToken: tokens.accessToken,
    refreshToken: tokens.refreshToken,
    tokenType: "Bearer",
    expiresIn: tokens.expiresIn,
    user: mobileUserPayload(user),
  };
}
