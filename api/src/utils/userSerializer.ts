import { User } from "@prisma/client";

export type PublicUser = {
  id: number;
  uuid: string;
  email: string;
  name: string;
  phone: string | null;
  avatarUrl: string | null;
  emailVerifiedAt: string | null;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
};

export function serializeUser(user: User): PublicUser {
  return {
    id: user.id,
    uuid: user.uuid,
    email: user.email,
    name: user.name,
    phone: user.phone,
    avatarUrl: user.avatarUrl,
    emailVerifiedAt: user.emailVerifiedAt?.toISOString() ?? null,
    isActive: user.isActive,
    createdAt: user.createdAt.toISOString(),
    updatedAt: user.updatedAt.toISOString(),
  };
}
