import type { Prisma, ReferralSettings } from "@prisma/client";
import { prisma } from "./prisma";

export type ReferralSourceType =
  | "LIVE_GIFT"
  | "VOICE_ROOM_GIFT"
  | "FAL_TRANSACTION"
  | "OTHER_ELIGIBLE_TRANSACTION";

export type ReferralCommissionStatus =
  | "PENDING"
  | "AVAILABLE"
  | "PAID"
  | "REVERSED"
  | "CANCELLED"
  | "CAPPED"
  | "FRAUD_HOLD";

export type EconomicSplitInput = {
  grossAmount: number;
  platformCommissionRate: number;
  referralRate: number;
};

export type EconomicSplitResult = {
  grossAmount: number;
  platformShare: number;
  beneficiaryShare: number;
  referralCommission: number;
  platformNet: number;
};

export type ReferralBeneficiaryInput = {
  userId: string;
  beneficiaryShare: number;
};

export type ProcessReferralInput = {
  transactionId: string;
  sourceType: ReferralSourceType;
  sourceId: string;
  grossAmount: number;
  beneficiaries: ReferralBeneficiaryInput[];
  fraudScore?: number;
  metadata?: Record<string, unknown>;
  settleImmediately?: boolean;
};

export type ProcessReferralResult = {
  ledgerEntries: Array<{
    id: string;
    referrerUserId: string;
    referredUserId: string;
    referralCommission: number;
    status: ReferralCommissionStatus;
    cappedAmount: number;
  }>;
};

const DEFAULT_SETTINGS: Omit<ReferralSettings, "updatedAt"> = {
  id: "default",
  livePlatformCommissionRate: 50,
  voiceRoomPlatformCommissionRate: 50,
  falPlatformCommissionRate: 50,
  otherPlatformCommissionRate: 50,
  referralCommissionRate: 5,
  normalReferralMonthlyCap: 10_000,
  foundingUserReferralMonthlyCap: 25_000,
  lifetimeReferralCap: 100_000,
  foundingUserLimit: 1000,
  foundingUserEnabled: true,
  pendingHours: 24,
  fraudHoldThreshold: 61,
  fraudBlockThreshold: 81,
  fraudReviewThreshold: 31,
};

export function calculateReferralFromBeneficiaryShare(
  beneficiaryShare: number,
  referralRate: number,
): { referralCommission: number } {
  const share = Math.max(0, Math.floor(beneficiaryShare));
  const rate = Math.min(100, Math.max(0, referralRate)) / 100;
  return { referralCommission: Math.floor(share * rate) };
}

export function calculateEconomicSplit(input: EconomicSplitInput): EconomicSplitResult {
  const gross = Math.max(0, Math.floor(input.grossAmount));
  const platformRate = Math.min(100, Math.max(0, input.platformCommissionRate)) / 100;
  const referralRate = Math.min(100, Math.max(0, input.referralRate)) / 100;

  const platformShare = Math.floor(gross * platformRate);
  const beneficiaryShare = gross - platformShare;
  const referralCommission = Math.floor(beneficiaryShare * referralRate);
  const platformNet = platformShare - referralCommission;

  if (beneficiaryShare + referralCommission + platformNet !== gross) {
    throw new Error(
      `INVARIANT_VIOLATION: ${beneficiaryShare}+${referralCommission}+${platformNet}!=${gross}`,
    );
  }
  if (referralCommission > platformShare) {
    throw new Error("INVARIANT_VIOLATION: referral exceeds platform share");
  }

  return {
    grossAmount: gross,
    platformShare,
    beneficiaryShare,
    referralCommission,
    platformNet,
  };
}

export function platformRateForSource(
  sourceType: ReferralSourceType,
  settings: ReferralSettings,
): number {
  switch (sourceType) {
    case "LIVE_GIFT":
      return settings.livePlatformCommissionRate;
    case "VOICE_ROOM_GIFT":
      return settings.voiceRoomPlatformCommissionRate;
    case "FAL_TRANSACTION":
      return settings.falPlatformCommissionRate;
    default:
      return settings.otherPlatformCommissionRate;
  }
}

export async function getReferralSettings(): Promise<ReferralSettings> {
  const row = await prisma.referralSettings.findUnique({ where: { id: "default" } });
  if (row) return row;
  return prisma.referralSettings.create({
    data: { ...DEFAULT_SETTINGS, updatedAt: new Date() },
  });
}

export async function updateReferralSettings(
  patch: Partial<Omit<ReferralSettings, "id" | "updatedAt">>,
): Promise<ReferralSettings> {
  await getReferralSettings();
  return prisma.referralSettings.update({
    where: { id: "default" },
    data: patch,
  });
}

function generateReferralCode(): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  let code = "";
  for (let i = 0; i < 8; i++) {
    code += chars[Math.floor(Math.random() * chars.length)];
  }
  return code;
}

export async function ensureUserReferralCode(userId: string): Promise<string> {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { referralCode: true },
  });
  if (user?.referralCode) return user.referralCode;

  for (let attempt = 0; attempt < 8; attempt++) {
    const code = generateReferralCode();
    try {
      const updated = await prisma.user.update({
        where: { id: userId },
        data: { referralCode: code },
        select: { referralCode: true },
      });
      if (updated.referralCode) return updated.referralCode;
    } catch {
      // unique collision — retry
    }
  }
  const fallback = userId.slice(-8).toUpperCase();
  await prisma.user.update({
    where: { id: userId },
    data: { referralCode: fallback },
  });
  return fallback;
}

export async function resolveReferrerByCode(
  referralCode: string | undefined | null,
): Promise<string | null> {
  const code = referralCode?.trim().toUpperCase();
  if (!code) return null;
  const byCode = await prisma.user.findFirst({
    where: { referralCode: code },
    select: { id: true },
  });
  if (byCode) return byCode.id;
  const bySuffix = await prisma.user.findFirst({
    where: { id: { endsWith: code.toLowerCase() } },
    select: { id: true },
  });
  return bySuffix?.id ?? null;
}

export async function linkReferralOnRegister(
  userId: string,
  referralCode: string | undefined | null,
): Promise<void> {
  const referrerId = await resolveReferrerByCode(referralCode);
  if (!referrerId || referrerId === userId) return;

  const existing = await prisma.user.findUnique({
    where: { id: userId },
    select: { referredByUserId: true },
  });
  if (existing?.referredByUserId) return;

  const settings = await getReferralSettings();
  const foundingCount = await prisma.user.count({
    where: { referredByUserId: { not: null } },
  });
  const isFounding =
    settings.foundingUserEnabled && foundingCount < settings.foundingUserLimit;

  await prisma.user.update({
    where: { id: userId },
    data: {
      referredByUserId: referrerId,
      referralJoinedAt: new Date(),
      referralStatus: "active",
      isFoundingUser: isFounding,
    },
  });
  await ensureUserReferralCode(userId);
}

async function sumReferralEarnings(
  referrerUserId: string,
  since?: Date,
  statuses: string[] = ["AVAILABLE", "PAID", "PENDING", "FRAUD_HOLD"],
): Promise<number> {
  const where: Prisma.ReferralCommissionLedgerWhereInput = {
    referrerUserId,
    status: { in: statuses },
    referralCommission: { gt: 0 },
  };
  if (since) where.createdAt = { gte: since };
  const agg = await prisma.referralCommissionLedger.aggregate({
    where,
    _sum: { referralCommission: true },
  });
  return agg._sum.referralCommission ?? 0;
}

function monthStart(): Date {
  const d = new Date();
  return new Date(d.getFullYear(), d.getMonth(), 1);
}

function resolveFraudStatus(
  fraudScore: number,
  settings: ReferralSettings,
): ReferralCommissionStatus {
  if (fraudScore >= settings.fraudBlockThreshold) return "CANCELLED";
  if (fraudScore >= settings.fraudHoldThreshold) return "FRAUD_HOLD";
  return "PENDING";
}

async function applyReferralPayout(
  tx: Prisma.TransactionClient,
  referrerUserId: string,
  amount: number,
): Promise<number> {
  if (amount <= 0) return 0;
  const user = await tx.user.findUnique({
    where: { id: referrerUserId },
    select: { referralDebtJeton: true },
  });
  const debt = user?.referralDebtJeton ?? 0;
  let payable = amount;
  let debtRecovery = 0;
  if (debt > 0) {
    debtRecovery = Math.min(debt, payable);
    payable -= debtRecovery;
    await tx.user.update({
      where: { id: referrerUserId },
      data: { referralDebtJeton: { decrement: debtRecovery } },
    });
    await tx.referralRecoveryLedger.create({
      data: {
        userId: referrerUserId,
        amount: debtRecovery,
        recovered: debtRecovery,
        reason: "auto_offset",
      },
    });
  }
  if (payable > 0) {
    await tx.user.update({
      where: { id: referrerUserId },
      data: { coins: { increment: payable } },
    });
  }
  return payable;
}

export async function processReferralCommission(
  input: ProcessReferralInput,
): Promise<ProcessReferralResult> {
  const settings = await getReferralSettings();
  const platformRate = platformRateForSource(input.sourceType, settings);
  const referralRate = settings.referralCommissionRate;
  const fraudScore = input.fraudScore ?? 0;
  const results: ProcessReferralResult["ledgerEntries"] = [];

  for (const beneficiary of input.beneficiaries) {
    if (!beneficiary.userId || beneficiary.beneficiaryShare <= 0) continue;

    const referred = await prisma.user.findUnique({
      where: { id: beneficiary.userId },
      select: {
        id: true,
        referredByUserId: true,
        referralStatus: true,
        isFoundingUser: true,
        referralFraudScore: true,
      },
    });
    if (!referred?.referredByUserId) continue;
    if (referred.referredByUserId === beneficiary.userId) continue;
    if (referred.referralStatus === "blocked") continue;

    const referrerUserId = referred.referredByUserId;
    const transactionId = `${input.transactionId}:${beneficiary.userId}`;

    const existing = await prisma.referralCommissionLedger.findUnique({
      where: {
        transactionId_referrerUserId: { transactionId, referrerUserId },
      },
    });
    if (existing) {
      results.push({
        id: existing.id,
        referrerUserId,
        referredUserId: beneficiary.userId,
        referralCommission: existing.referralCommission,
        status: existing.status as ReferralCommissionStatus,
        cappedAmount: existing.cappedAmount,
      });
      continue;
    }

    const split = calculateEconomicSplit({
      grossAmount: input.grossAmount,
      platformCommissionRate: platformRate,
      referralRate,
    });

    const beneficiaryReferral = calculateReferralFromBeneficiaryShare(
      beneficiary.beneficiaryShare,
      referralRate,
    );
    const referralCommission = beneficiaryReferral.referralCommission;

    if (referralCommission <= 0) continue;

    const platformShareOnBeneficiary = Math.floor(
      beneficiary.beneficiaryShare / (1 - platformRate / 100) -
        beneficiary.beneficiaryShare,
    );
    const platformNetOnBeneficiary = Math.max(
      0,
      platformShareOnBeneficiary - referralCommission,
    );

    const combinedFraud = Math.max(fraudScore, referred.referralFraudScore ?? 0);
    let status: ReferralCommissionStatus = resolveFraudStatus(combinedFraud, settings);
    let payable = referralCommission;
    let cappedAmount = 0;

    if (status !== "CANCELLED" && status !== "FRAUD_HOLD") {
      const monthlyCap = referred.isFoundingUser
        ? settings.foundingUserReferralMonthlyCap
        : settings.normalReferralMonthlyCap;
      const monthlyEarned = await sumReferralEarnings(referrerUserId, monthStart());
      const lifetimeEarned = await sumReferralEarnings(referrerUserId);

      if (lifetimeEarned + payable > settings.lifetimeReferralCap) {
        const allowed = Math.max(0, settings.lifetimeReferralCap - lifetimeEarned);
        cappedAmount += payable - allowed;
        payable = allowed;
        if (payable <= 0) status = "CAPPED";
      }
      if (payable > 0 && monthlyEarned + payable > monthlyCap) {
        const allowed = Math.max(0, monthlyCap - monthlyEarned);
        cappedAmount += payable - allowed;
        payable = allowed;
        if (payable <= 0) status = "CAPPED";
      }
    }

    const availableAt = new Date(
      Date.now() + settings.pendingHours * 60 * 60 * 1000,
    );
    const finalStatus =
      status === "CAPPED"
        ? "CAPPED"
        : input.settleImmediately
          ? "AVAILABLE"
          : status;

    const ledger = await prisma.$transaction(async (tx) => {
      const entry = await tx.referralCommissionLedger.create({
        data: {
          transactionId,
          referrerUserId,
          referredUserId: beneficiary.userId,
          sourceType: input.sourceType,
          sourceId: input.sourceId,
          grossJeton: input.grossAmount,
          beneficiaryShare: beneficiary.beneficiaryShare,
          platformShare: split.platformShare,
          referralRate,
          referralCommission: payable,
          platformNet: platformNetOnBeneficiary,
          status: finalStatus,
          fraudScore: combinedFraud,
          cappedAmount,
          metadata: input.metadata ? JSON.stringify(input.metadata) : null,
          availableAt:
            finalStatus === "AVAILABLE" || finalStatus === "PAID"
              ? new Date()
              : availableAt,
        },
      });

      if (
        (finalStatus === "AVAILABLE" || finalStatus === "PAID") &&
        payable > 0
      ) {
        const paid = await applyReferralPayout(tx, referrerUserId, payable);
        if (paid > 0) {
          await tx.referralCommissionLedger.update({
            where: { id: entry.id },
            data: { status: "PAID" },
          });
        }
      }

      return entry;
    });

    results.push({
      id: ledger.id,
      referrerUserId,
      referredUserId: beneficiary.userId,
      referralCommission: payable,
      status: (ledger.status === "PAID"
        ? "PAID"
        : finalStatus) as ReferralCommissionStatus,
      cappedAmount,
    });
  }

  return { ledgerEntries: results };
}

export async function reverseReferralCommission(
  sourceId: string,
  reason: string,
): Promise<number> {
  const rows = await prisma.referralCommissionLedger.findMany({
    where: {
      sourceId,
      status: { in: ["PENDING", "AVAILABLE", "PAID"] },
    },
  });
  let reversed = 0;
  for (const row of rows) {
    await prisma.$transaction(async (tx) => {
      if (row.status === "PAID" && row.referralCommission > 0) {
        const user = await tx.user.findUnique({
          where: { id: row.referrerUserId },
          select: { coins: true },
        });
        const balance = user?.coins ?? 0;
        if (balance >= row.referralCommission) {
          await tx.user.update({
            where: { id: row.referrerUserId },
            data: { coins: { decrement: row.referralCommission } },
          });
        } else {
          const shortfall = row.referralCommission - balance;
          if (balance > 0) {
            await tx.user.update({
              where: { id: row.referrerUserId },
              data: { coins: 0 },
            });
          }
          await tx.user.update({
            where: { id: row.referrerUserId },
            data: { referralDebtJeton: { increment: shortfall } },
          });
          await tx.referralRecoveryLedger.create({
            data: {
              userId: row.referrerUserId,
              ledgerId: row.id,
              amount: shortfall,
              reason,
            },
          });
        }
      }
      await tx.referralCommissionLedger.update({
        where: { id: row.id },
        data: {
          status: "REVERSED",
          reversedAt: new Date(),
          reverseReason: reason,
        },
      });
    });
    reversed++;
  }
  return reversed;
}

export async function settlePendingReferrals(): Promise<number> {
  const now = new Date();
  const pending = await prisma.referralCommissionLedger.findMany({
    where: {
      status: { in: ["PENDING"] },
      availableAt: { lte: now },
      referralCommission: { gt: 0 },
    },
    take: 200,
  });
  let settled = 0;
  for (const row of pending) {
    await prisma.$transaction(async (tx) => {
      const paid = await applyReferralPayout(
        tx,
        row.referrerUserId,
        row.referralCommission,
      );
      await tx.referralCommissionLedger.update({
        where: { id: row.id },
        data: { status: paid > 0 ? "PAID" : "AVAILABLE" },
      });
    });
    settled++;
  }
  return settled;
}

export async function getReferralStatsForUser(userId: string) {
  const settings = await getReferralSettings();
  const code = await ensureUserReferralCode(userId);
  const origin = (process.env.PUBLIC_SITE_URL ?? "https://canlifal.com").replace(
    /\/$/,
    "",
  );

  const invitedCount = await prisma.user.count({
    where: { referredByUserId: userId },
  });
  const activeCount = await prisma.user.count({
    where: {
      referredByUserId: userId,
      referralCommissionsSource: { some: {} },
    },
  });

  const monthStartDate = monthStart();
  const [
    totalEarned,
    monthEarned,
    pendingEarned,
    availableEarned,
    reversedEarned,
    cappedEarned,
    lifetimeEarned,
  ] = await Promise.all([
    sumReferralEarnings(userId, undefined, ["PAID", "AVAILABLE"]),
    sumReferralEarnings(userId, monthStartDate, ["PAID", "AVAILABLE"]),
    sumReferralEarnings(userId, undefined, ["PENDING", "FRAUD_HOLD"]),
    sumReferralEarnings(userId, undefined, ["AVAILABLE"]),
    sumReferralEarnings(userId, undefined, ["REVERSED"]),
    sumReferralEarnings(userId, undefined, ["CAPPED"]),
    sumReferralEarnings(userId),
  ]);

  const monthlyCap =
    (await prisma.user.findUnique({
      where: { id: userId },
      select: { isFoundingUser: true },
    }))?.isFoundingUser
      ? settings.foundingUserReferralMonthlyCap
      : settings.normalReferralMonthlyCap;

  return {
    referralCode: code,
    shareUrl: `${origin}/davet?ref=${code}`,
    inviteLink: `${origin}/davet?ref=${code}`,
    headline:
      "Arkadaşını Canlifal'e davet et. Arkadaşın uygun gerçek hizmet işlemleri gerçekleştirdiğinde, platformun referans programı kapsamında ödül kazanabilirsin.",
    rewardHint:
      "Kayıt veya jeton yüklemesi tek başına komisyon oluşturmaz.",
    invitedCount,
    activeReferralCount: activeCount,
    totalEarnings: totalEarned,
    monthEarnings: monthEarned,
    pendingEarnings: pendingEarned,
    availableEarnings: availableEarned,
    reversedEarnings: reversedEarned,
    cappedEarnings: cappedEarned,
    lifetimeEarnings: lifetimeEarned,
    monthlyLimit: monthlyCap,
    lifetimeLimit: settings.lifetimeReferralCap,
    settings: {
      referralCommissionRate: settings.referralCommissionRate,
      livePlatformCommissionRate: settings.livePlatformCommissionRate,
      voiceRoomPlatformCommissionRate: settings.voiceRoomPlatformCommissionRate,
      falPlatformCommissionRate: settings.falPlatformCommissionRate,
      otherPlatformCommissionRate: settings.otherPlatformCommissionRate,
    },
  };
}
