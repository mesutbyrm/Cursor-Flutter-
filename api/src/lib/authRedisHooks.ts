import { presenceSetOffline, presenceSetOnline } from "./redis/presence";
import { sessionClear, sessionSetActive } from "./redis/session";

/** Giriş sonrası Redis session + presence (JWT değişmez). */
export async function onAuthLogin(
  userId: string,
  meta?: { displayName?: string; platform?: string; ip?: string },
): Promise<void> {
  await sessionSetActive(userId, {
    platform: meta?.platform,
    ip: meta?.ip,
  });
  await presenceSetOnline(userId, { displayName: meta?.displayName });
}

/** Çıkış — aktif oturum ve presence temizle */
export async function onAuthLogout(userId: string): Promise<void> {
  await sessionClear(userId);
  await presenceSetOffline(userId);
}
