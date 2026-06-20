import type { RoomType, VoiceRoomSettings } from "@prisma/client";
import { prisma } from "./prisma";

export type GiftSplitResult = {
  total: number;
  roomType: RoomType;
  receiverGross: number;
  receiverNet: number;
  ownerGross: number;
  ownerNet: number;
  siteAmount: number;
  receiverCommission: number;
  ownerCommission: number;
  siteFromOwnerShare: number;
};

export type MusicSplitResult = {
  total: number;
  roomType: RoomType;
  ownerNet: number;
  siteAmount: number;
};

/** Hediye paylaşımı — komisyon brüt paylar üzerinden (toplam üzerinden değil). */
export function calculateGiftSplit(
  total: number,
  roomType: RoomType,
  settings: Pick<
    VoiceRoomSettings,
    "giftReceiverPercent" | "roomOwnerPercent" | "siteCommissionPercent"
  >,
): GiftSplitResult {
  if (total <= 0) {
    return {
      total: 0,
      roomType,
      receiverGross: 0,
      receiverNet: 0,
      ownerGross: 0,
      ownerNet: 0,
      siteAmount: 0,
      receiverCommission: 0,
      ownerCommission: 0,
      siteFromOwnerShare: 0,
    };
  }

  const commRate = settings.siteCommissionPercent / 100;
  const receiverGross = Math.floor(total * (settings.giftReceiverPercent / 100));
  const ownerGrossNominal = Math.floor(total * (settings.roomOwnerPercent / 100));
  const ownerGross = roomType === "FREE" ? 0 : ownerGrossNominal;
  const siteFromOwnerShare = roomType === "FREE" ? ownerGrossNominal : 0;
  const remainder = total - receiverGross - ownerGrossNominal;

  const receiverCommission = Math.floor(receiverGross * commRate);
  const ownerCommission = Math.floor(ownerGross * commRate);
  const receiverNet = receiverGross - receiverCommission;
  const ownerNet = ownerGross - ownerCommission;
  const siteAmount =
    receiverCommission + ownerCommission + siteFromOwnerShare + Math.max(0, remainder);

  return {
    total,
    roomType,
    receiverGross,
    receiverNet,
    ownerGross,
    ownerNet,
    siteAmount,
    receiverCommission,
    ownerCommission,
    siteFromOwnerShare,
  };
}

/** Müzik isteği paylaşımı — oda türüne göre (komisyon yok, doğrudan bölüşüm). */
export function calculateMusicSplit(
  total: number,
  roomType: RoomType,
  settings: Pick<
    VoiceRoomSettings,
    | "musicOwnerPercent"
    | "musicSitePercent"
    | "vipMusicOwnerPercent"
    | "vipMusicSitePercent"
  >,
): MusicSplitResult {
  if (total <= 0) {
    return { total: 0, roomType, ownerNet: 0, siteAmount: 0 };
  }

  if (roomType === "FREE") {
    return { total, roomType, ownerNet: 0, siteAmount: total };
  }

  if (roomType === "VIP") {
    const ownerNet = Math.floor(total * (settings.vipMusicOwnerPercent / 100));
    return { total, roomType, ownerNet, siteAmount: total - ownerNet };
  }

  const ownerNet = Math.floor(total * (settings.musicOwnerPercent / 100));
  return { total, roomType, ownerNet, siteAmount: total - ownerNet };
}

export type ApplyGiftPayoutInput = {
  roomId: string;
  roomType: RoomType;
  senderId: string;
  receiverId: string | null;
  ownerId: string | null;
  totalCost: number;
  giftEventId: string;
  settings: VoiceRoomSettings;
};

export async function applyGiftPayout(input: ApplyGiftPayoutInput) {
  const split = calculateGiftSplit(input.totalCost, input.roomType, input.settings);

  await prisma.$transaction(async (tx) => {
    const credits: Array<{ userId: string; amount: number }> = [];
    if (input.receiverId && split.receiverNet > 0) {
      credits.push({ userId: input.receiverId, amount: split.receiverNet });
    }
    if (input.ownerId && split.ownerNet > 0) {
      credits.push({ userId: input.ownerId, amount: split.ownerNet });
    }
    for (const c of credits) {
      await tx.user.update({
        where: { id: c.userId },
        data: { coins: { increment: c.amount } },
      });
    }

    await tx.giftEvent.update({
      where: { id: input.giftEventId },
      data: {
        roomType: input.roomType,
        receiverGross: split.receiverGross,
        receiverNet: split.receiverNet,
        ownerGross: split.ownerGross,
        ownerNet: split.ownerNet,
        siteAmount: split.siteAmount,
      },
    });

    await tx.voiceRoomFinanceAuditLog.create({
      data: {
        roomId: input.roomId,
        roomType: input.roomType,
        transactionType: "gift",
        actorId: input.senderId,
        totalAmount: input.totalCost,
        receiverId: input.receiverId,
        receiverGross: split.receiverGross,
        receiverNet: split.receiverNet,
        ownerId: input.ownerId,
        ownerGross: split.ownerGross,
        ownerNet: split.ownerNet,
        siteAmount: split.siteAmount,
        giftEventId: input.giftEventId,
        metadata: JSON.stringify({
          receiverCommission: split.receiverCommission,
          ownerCommission: split.ownerCommission,
          siteFromOwnerShare: split.siteFromOwnerShare,
        }),
      },
    });
  });

  return split;
}

export type ApplyMusicPayoutInput = {
  roomId: string;
  roomType: RoomType;
  requesterId: string;
  ownerId: string | null;
  totalCost: number;
  songName: string;
  settings: VoiceRoomSettings;
};

export async function applyMusicPayout(input: ApplyMusicPayoutInput) {
  const split = calculateMusicSplit(input.totalCost, input.roomType, input.settings);

  await prisma.$transaction(async (tx) => {
    if (input.ownerId && split.ownerNet > 0) {
      await tx.user.update({
        where: { id: input.ownerId },
        data: { coins: { increment: split.ownerNet } },
      });
    }

    await tx.voiceRoomFinanceAuditLog.create({
      data: {
        roomId: input.roomId,
        roomType: input.roomType,
        transactionType: "music_request",
        actorId: input.requesterId,
        totalAmount: input.totalCost,
        ownerId: input.ownerId,
        ownerNet: split.ownerNet,
        siteAmount: split.siteAmount,
        metadata: JSON.stringify({ songName: input.songName }),
      },
    });
  });

  return split;
}

export function giftSplitPayload(split: GiftSplitResult) {
  return {
    total: split.total,
    roomType: split.roomType,
    receiver: {
      gross: split.receiverGross,
      net: split.receiverNet,
      commission: split.receiverCommission,
    },
    owner: {
      gross: split.ownerGross,
      net: split.ownerNet,
      commission: split.ownerCommission,
    },
    site: {
      amount: split.siteAmount,
      fromOwnerShare: split.siteFromOwnerShare,
    },
  };
}

export function musicSplitPayload(split: MusicSplitResult) {
  return {
    total: split.total,
    roomType: split.roomType,
    owner: { net: split.ownerNet },
    site: { amount: split.siteAmount },
  };
}
