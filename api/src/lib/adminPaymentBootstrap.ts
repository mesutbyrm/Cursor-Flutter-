import { prisma } from "./prisma";
import { effectiveStaffRole, isAdminOrManager } from "./staffAccess";

/** `admin` / `yonetici` kullanıcı adlarını uygun role yükseltir. */
export async function ensureAdminUsers(): Promise<number> {
  const users = await prisma.user.findMany({
    where: { username: { not: null } },
    select: { id: true, username: true, role: true },
  });
  let updated = 0;
  for (const u of users) {
    const name = u.username?.toLowerCase().trim() ?? "";
    let target: string | null = null;
    if (name === "admin") target = "admin";
    if (name === "yonetici") target = "yonetici";
    if (target == null || u.role.toLowerCase() === target) continue;
    await prisma.user.update({
      where: { id: u.id },
      data: { role: target },
    });
    updated++;
  }
  return updated;
}

/** Bekleyen tüm ödeme taleplerini reddeder (kuyruk temizliği). */
export async function dismissAllPendingPaymentRequests(
  actorId?: string | null,
): Promise<number> {
  const note =
    "Toplu kapatıldı — yeni ödeme talebi gönderebilirsiniz.";
  const result = await prisma.cfcPaymentRequest.updateMany({
    where: { status: "pending" },
    data: {
      status: "rejected",
      reviewNote: note,
      reviewedBy: actorId ?? null,
    },
  });
  return result.count;
}

/** Sunucu açılışında admin hesabı + bekleyen talep temizliği. */
export async function runAdminPaymentBootstrap(): Promise<void> {
  if (!process.env.DATABASE_URL) return;
  try {
    const promoted = await ensureAdminUsers();
    if (promoted > 0) {
      console.info(
        `[admin-bootstrap] ${promoted} kullanıcı admin/yönetici rolüne yükseltildi`,
      );
    }
    const dismissed = await dismissAllPendingPaymentRequests(null);
    if (dismissed > 0) {
      console.info(
        `[admin-bootstrap] ${dismissed} bekleyen ödeme talebi kapatıldı`,
      );
    }
  } catch (err) {
    console.error("[admin-bootstrap] failed", err);
  }
}

/** Ödeme bildirimi alacak admin kullanıcı id'leri. */
export async function listPaymentAlertUserIds(): Promise<string[]> {
  const users = await prisma.user.findMany({
    where: {
      OR: [
        { username: { equals: "admin", mode: "insensitive" } },
        { username: { equals: "yonetici", mode: "insensitive" } },
        {
          role: {
            in: ["admin", "yonetici", "super_admin", "superadmin", "founder"],
          },
        },
      ],
    },
    select: { id: true, username: true, role: true },
  });
  const ids = new Set<string>();
  for (const u of users) {
    if (isAdminOrManager(u)) ids.add(u.id);
  }
  return [...ids];
}
