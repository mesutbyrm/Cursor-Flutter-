import { prisma } from "./prisma";
import { sendOneSignalToUser } from "./onesignal";

export async function createNotification(input: {
  userId?: string;
  title: string;
  body?: string;
  type?: string;
  data?: string | Record<string, unknown>;
  targetPath?: string;
  targetId?: string;
  /** true → OneSignal yüksek öncelik (mesaj, ödeme, canlı) */
  urgent?: boolean;
}) {
  const dataStr =
    input.data == null
      ? undefined
      : typeof input.data === "string"
        ? input.data
        : JSON.stringify(input.data);
  const row = await prisma.appNotification.create({
    data: {
      userId: input.userId ?? null,
      title: input.title,
      body: input.body,
      type: input.type ?? "system",
      data: dataStr,
      targetPath: input.targetPath,
      targetId: input.targetId,
    },
  });

  if (input.userId) {
    const extra: Record<string, string> = {
      title: input.title,
      type: input.type ?? "system",
      event: input.type ?? "system",
    };
    if (input.body) extra.body = input.body;
    if (input.targetPath) extra.targetPath = input.targetPath;
    if (input.targetId) extra.targetId = input.targetId;
    // data içindeki tüm alanları ekle (sessionId, tellerId vb.)
    if (input.data && typeof input.data === 'object') {
      const d = input.data as Record<string, unknown>;
      for (const [k, v] of Object.entries(d)) {
        if (v != null) extra[k] = String(v);
      }
    }
    // Sadece OneSignal kullan — FCM ayrıca çağrılmıyor (çift bildirim önleme)
    const pushResult = await sendOneSignalToUser({
      userId: input.userId,
      title: input.title,
      body: input.body,
      data: extra,
      urgent: input.urgent ?? isUrgentNotificationType(input.type),
    });
    if (!pushResult.ok) {
      console.warn(
        `[createNotification] OneSignal failed userId=${input.userId} status=${pushResult.status ?? ""} err=${pushResult.error ?? ""}`,
      );
    } else {
      console.info(
        `[createNotification] OneSignal ok userId=${input.userId} status=${pushResult.status ?? 200}`,
      );
    }
  }

  return row;
}

function isUrgentNotificationType(type?: string): boolean {
  if (!type) return false;
  const t = type.toLowerCase();
  return (
    t === "message" ||
    t === "live" ||
    t === "fortune_session_invite" ||
    t.includes("payment") ||
    t.includes("jeton") ||
    t.includes("cfc") ||
    t.startsWith("admin")
  );
}
