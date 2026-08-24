-- Referral / agency commission system

ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "referralCode" TEXT;
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "referredByUserId" TEXT;
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "referralJoinedAt" TIMESTAMP(3);
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "referralStatus" TEXT NOT NULL DEFAULT 'active';
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "isFoundingUser" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "referralFraudScore" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "referralDebtJeton" INTEGER NOT NULL DEFAULT 0;

CREATE UNIQUE INDEX IF NOT EXISTS "User_referralCode_key" ON "User"("referralCode");
CREATE INDEX IF NOT EXISTS "User_referredByUserId_idx" ON "User"("referredByUserId");
CREATE INDEX IF NOT EXISTS "User_referralCode_idx" ON "User"("referralCode");

ALTER TABLE "User" ADD CONSTRAINT "User_referredByUserId_fkey"
  FOREIGN KEY ("referredByUserId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

CREATE TABLE IF NOT EXISTS "referral_settings" (
  "id" TEXT NOT NULL,
  "livePlatformCommissionRate" INTEGER NOT NULL DEFAULT 50,
  "voiceRoomPlatformCommissionRate" INTEGER NOT NULL DEFAULT 50,
  "falPlatformCommissionRate" INTEGER NOT NULL DEFAULT 50,
  "otherPlatformCommissionRate" INTEGER NOT NULL DEFAULT 50,
  "referralCommissionRate" INTEGER NOT NULL DEFAULT 5,
  "normalReferralMonthlyCap" INTEGER NOT NULL DEFAULT 10000,
  "foundingUserReferralMonthlyCap" INTEGER NOT NULL DEFAULT 25000,
  "lifetimeReferralCap" INTEGER NOT NULL DEFAULT 100000,
  "foundingUserLimit" INTEGER NOT NULL DEFAULT 1000,
  "foundingUserEnabled" BOOLEAN NOT NULL DEFAULT true,
  "pendingHours" INTEGER NOT NULL DEFAULT 24,
  "fraudHoldThreshold" INTEGER NOT NULL DEFAULT 61,
  "fraudBlockThreshold" INTEGER NOT NULL DEFAULT 81,
  "fraudReviewThreshold" INTEGER NOT NULL DEFAULT 31,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "referral_settings_pkey" PRIMARY KEY ("id")
);

INSERT INTO "referral_settings" ("id", "updatedAt")
VALUES ('default', CURRENT_TIMESTAMP)
ON CONFLICT ("id") DO NOTHING;

CREATE TABLE IF NOT EXISTS "referral_commission_ledger" (
  "id" TEXT NOT NULL,
  "transactionId" TEXT NOT NULL,
  "referrerUserId" TEXT NOT NULL,
  "referredUserId" TEXT NOT NULL,
  "sourceType" TEXT NOT NULL,
  "sourceId" TEXT NOT NULL,
  "grossJeton" INTEGER NOT NULL,
  "beneficiaryShare" INTEGER NOT NULL,
  "platformShare" INTEGER NOT NULL,
  "referralRate" INTEGER NOT NULL,
  "referralCommission" INTEGER NOT NULL,
  "platformNet" INTEGER NOT NULL,
  "status" TEXT NOT NULL DEFAULT 'PENDING',
  "fraudScore" INTEGER NOT NULL DEFAULT 0,
  "cappedAmount" INTEGER NOT NULL DEFAULT 0,
  "metadata" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "availableAt" TIMESTAMP(3),
  "reversedAt" TIMESTAMP(3),
  "reverseReason" TEXT,
  CONSTRAINT "referral_commission_ledger_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "referral_commission_ledger_transactionId_referrerUserId_key"
  ON "referral_commission_ledger"("transactionId", "referrerUserId");
CREATE INDEX IF NOT EXISTS "referral_commission_ledger_referrerUserId_createdAt_idx"
  ON "referral_commission_ledger"("referrerUserId", "createdAt");
CREATE INDEX IF NOT EXISTS "referral_commission_ledger_referredUserId_createdAt_idx"
  ON "referral_commission_ledger"("referredUserId", "createdAt");
CREATE INDEX IF NOT EXISTS "referral_commission_ledger_sourceType_sourceId_idx"
  ON "referral_commission_ledger"("sourceType", "sourceId");
CREATE INDEX IF NOT EXISTS "referral_commission_ledger_status_createdAt_idx"
  ON "referral_commission_ledger"("status", "createdAt");

ALTER TABLE "referral_commission_ledger" ADD CONSTRAINT "referral_commission_ledger_referrerUserId_fkey"
  FOREIGN KEY ("referrerUserId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "referral_commission_ledger" ADD CONSTRAINT "referral_commission_ledger_referredUserId_fkey"
  FOREIGN KEY ("referredUserId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

CREATE TABLE IF NOT EXISTS "referral_recovery_ledger" (
  "id" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "ledgerId" TEXT,
  "amount" INTEGER NOT NULL,
  "recovered" INTEGER NOT NULL DEFAULT 0,
  "reason" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "referral_recovery_ledger_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "referral_recovery_ledger_userId_createdAt_idx"
  ON "referral_recovery_ledger"("userId", "createdAt");
