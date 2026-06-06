import { prisma } from "./prisma";
import { createNotification } from "./notifications";

const STAFF_ROLES = ["admin", "yonetici", "moderator", "destek", "yardim"] as const;

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
}) {
  const staff = await prisma.user.findMany({
    where: { role: { in: [...STAFF_ROLES] } },
    select: { id: true },
  });
  const isJeton = input.requestType === "jeton";
  const title = isJeton
    ? "Jeton ödemesi — onay bekliyor"
    : "CFC ödemesi — onay bekliyor";
  const body = `${input.amountLabel} · ${input.method}`;
  const type = isJeton ? "jeton_payment_request" : "cfc_payment_request";

  const data = {
    paymentRequestId: input.paymentRequestId,
    requestType: input.requestType,
    method: input.method,
  };

  await Promise.all(
    staff.map((s) =>
      createNotification({
        userId: s.id,
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
