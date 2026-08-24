import {
  getReferralSettings,
  platformRateForSource,
  processReferralCommission,
} from "./referralCommissionService";

/** Canlı yayın hediyesi — yayıncı hakedişi üzerinden tek seviye referans. */
export async function processLiveGiftReferral(input: {
  giftEventId: string;
  grossAmount: number;
  receiverId: string | null;
}) {
  if (!input.receiverId || input.grossAmount <= 0) return;
  const settings = await getReferralSettings();
  const platformRate = platformRateForSource("LIVE_GIFT", settings);
  const beneficiaryShare = Math.floor(
    input.grossAmount * (1 - platformRate / 100),
  );
  if (beneficiaryShare <= 0) return;

  await processReferralCommission({
    transactionId: input.giftEventId,
    sourceType: "LIVE_GIFT",
    sourceId: input.giftEventId,
    grossAmount: input.grossAmount,
    beneficiaries: [{ userId: input.receiverId, beneficiaryShare }],
    settleImmediately: true,
  });
}

/** Sesli oda hediyesi — yalnızca gerçek hakediş alan kullanıcılar. */
export async function processVoiceRoomGiftReferral(input: {
  giftEventId: string;
  grossAmount: number;
  receiverId: string | null;
  receiverNet: number;
  ownerId: string | null;
  ownerNet: number;
}) {
  const beneficiaries: Array<{ userId: string; beneficiaryShare: number }> = [];
  if (input.receiverId && input.receiverNet > 0) {
    beneficiaries.push({
      userId: input.receiverId,
      beneficiaryShare: input.receiverNet,
    });
  }
  if (input.ownerId && input.ownerNet > 0) {
    beneficiaries.push({
      userId: input.ownerId,
      beneficiaryShare: input.ownerNet,
    });
  }
  if (beneficiaries.length === 0) return;

  await processReferralCommission({
    transactionId: input.giftEventId,
    sourceType: "VOICE_ROOM_GIFT",
    sourceId: input.giftEventId,
    grossAmount: input.grossAmount,
    beneficiaries,
    settleImmediately: true,
  });
}
