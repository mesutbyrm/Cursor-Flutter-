import { prisma } from "./prisma";
import { createNotification } from "./notifications";
import {
  PAYMENT_ALERT_EMAIL,
  sendPaymentAdminEmail,
} from "./payment_admin_email";

const STAFF_ROLES = ["admin", "yonetici", "moderator", "destek", "yardim"] as const;
const PAYMENT_FALLBACK_EMAIL = process.env.PAYMENT_ALERT_EMAIL ?? "mesutbyrm1@gmail.com";
/** Yeni DM — alıcıya anında push */
export async function notifyDirectMessage(input: {
  conversationId: string;
  senderId: string;
  recipientId: string;
  preview: string;
  senderLabel?: string;
}) {
  const title = input.senderLabel?.trim() || "Yeni mesaj";
  const body =
    input.preview.length > 120
      ? `${input.preview.slice(0, 117)}…`
      : input.preview;

  await createNotification({
    userId: input.recipientId,
    title,
    body,
    type: "message",
    targetPath: `/chat/${input.conversationId}`,
    targetId: input.conversationId,
    urgent: true,
  });
}

/** Bekleyen jeton/CFC ödemesi — tüm staff hesaplarına push */
export async function notifyStaffPaymentPending(input: {
  paymentRequestId: string;
  requestType: "jeton" | "cfc";
  amountLabel: string;
  method: string;
  username?: string;
  packageName?: string;
  amountTry?: number;
  senderInfo?: string | null;
  notes?: string | null;
}) {
  const staffByRole = await prisma.user.findMany({
    where: { role: { in: [...STAFF_ROLES] } },
    select: { id: true },
  });
  const staffByUsername = await prisma.user.findMany({
    where: { username: { in: ["admin", "yonetici"] } },
    select: { id: true },
  });
  const isJeton = input.requestType === "jeton";
  const title = "Yeni ödeme bildirimi alındı";
  const amountText =
    input.amountTry != null && Number.isFinite(input.amountTry)
      ? `${input.amountTry} TL`
      : input.amountLabel;
  const body = [
    `Kullanıcı: ${input.username ?? "—"}`,
    `Paket: ${input.packageName ?? input.amountLabel}`,
    `Tutar: ${amountText}`,
    `Yöntem: ${input.method}`,
  ].join("\n");
  const type = isJeton ? "jeton_payment_request" : "cfc_payment_request";

  const data = {
    paymentRequestId: input.paymentRequestId,
    requestType: input.requestType,
    method: input.method,
  };

  const notifyIds = new Set([
    ...staffByRole.map((s) => s.id),
    ...staffByUsername.map((s) => s.id),
  ]);

  // Admin e-posta hesabı staff listesinde değilse uygulama içi bildirim de gönder.
  const alertUser = await prisma.user.findUnique({
    where: { email: PAYMENT_FALLBACK_EMAIL },
    select: { id: true },
  });
  if (alertUser) {
    notifyIds.add(alertUser.id);
  }

  await Promise.all(
    [...notifyIds].map((userId) =>
      createNotification({
        userId,
        title,
        body,
        type,
        data,
        targetPath: "/admin",
        targetId: input.paymentRequestId,
        urgent: true,
      }),
    ),
  );

  await sendPaymentAdminEmail({
    paymentRequestId: input.paymentRequestId,
    requestType: input.requestType,
    amountLabel: input.amountLabel,
    method: input.method,
    username: input.username,
    packageName: input.packageName,
    amountTry: input.amountTry,
    senderInfo: input.senderInfo,
    notes: input.notes,
  });
}

/** Yayıncı canlıya geçti — takipçilere push */
export async function notifyFollowersLiveStarted(input: {
  broadcasterId: string;
  streamId: string;
  title: string;
  broadcasterName: string;
}) {
  const followers = await prisma.follow.findMany({
    where: { followingId: input.broadcasterId },
    select: { followerId: true },
    take: 500,
  });
  if (followers.length === 0) return;

  const pushTitle = `${input.broadcasterName} canlı yayında`;
  const body = input.title.trim() || "Canlı yayına katıl";

  await Promise.all(
    followers.map((f) =>
      createNotification({
        userId: f.followerId,
        title: pushTitle,
        body,
        type: "live",
        targetPath: "/live",
        targetId: input.streamId,
        urgent: true,
      }),
    ),
  );
}
