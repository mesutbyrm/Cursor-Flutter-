-- CreateEnum
CREATE TYPE "RoomType" AS ENUM ('FREE', 'NORMAL', 'VIP');

-- AlterTable gift_events
ALTER TABLE "GiftEvent" ADD COLUMN IF NOT EXISTS "roomType" TEXT;
ALTER TABLE "GiftEvent" ADD COLUMN IF NOT EXISTS "receiverGross" INTEGER;
ALTER TABLE "GiftEvent" ADD COLUMN IF NOT EXISTS "receiverNet" INTEGER;
ALTER TABLE "GiftEvent" ADD COLUMN IF NOT EXISTS "ownerGross" INTEGER;
ALTER TABLE "GiftEvent" ADD COLUMN IF NOT EXISTS "ownerNet" INTEGER;
ALTER TABLE "GiftEvent" ADD COLUMN IF NOT EXISTS "siteAmount" INTEGER;

-- CreateTable voice_rooms
CREATE TABLE IF NOT EXISTS "voice_rooms" (
    "id" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "nameTr" TEXT NOT NULL,
    "descTr" TEXT,
    "icon" TEXT,
    "backgroundImage" TEXT,
    "ownerId" TEXT NOT NULL,
    "roomType" "RoomType" NOT NULL DEFAULT 'NORMAL',
    "maxUsers" INTEGER NOT NULL DEFAULT 100,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "voice_rooms_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "voice_rooms_slug_key" ON "voice_rooms"("slug");
CREATE INDEX IF NOT EXISTS "voice_rooms_roomType_isActive_idx" ON "voice_rooms"("roomType", "isActive");
CREATE INDEX IF NOT EXISTS "voice_rooms_ownerId_idx" ON "voice_rooms"("ownerId");

-- CreateTable voice_room_settings
CREATE TABLE IF NOT EXISTS "voice_room_settings" (
    "id" TEXT NOT NULL DEFAULT 'default',
    "giftReceiverPercent" INTEGER NOT NULL DEFAULT 70,
    "roomOwnerPercent" INTEGER NOT NULL DEFAULT 30,
    "siteCommissionPercent" INTEGER NOT NULL DEFAULT 50,
    "musicOwnerPercent" INTEGER NOT NULL DEFAULT 50,
    "musicSitePercent" INTEGER NOT NULL DEFAULT 50,
    "vipMusicOwnerPercent" INTEGER NOT NULL DEFAULT 70,
    "vipMusicSitePercent" INTEGER NOT NULL DEFAULT 30,
    "musicRequestCost" INTEGER NOT NULL DEFAULT 10,
    "freeRoomMaxUsers" INTEGER NOT NULL DEFAULT 15,
    "normalRoomMaxUsers" INTEGER NOT NULL DEFAULT 100,
    "vipRoomMaxUsers" INTEGER NOT NULL DEFAULT 500,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "voice_room_settings_pkey" PRIMARY KEY ("id")
);

INSERT INTO "voice_room_settings" ("id", "updatedAt")
VALUES ('default', CURRENT_TIMESTAMP)
ON CONFLICT ("id") DO NOTHING;

-- CreateTable voice_room_finance_audit_log
CREATE TABLE IF NOT EXISTS "voice_room_finance_audit_log" (
    "id" TEXT NOT NULL,
    "roomId" TEXT,
    "roomType" TEXT,
    "transactionType" TEXT NOT NULL,
    "actorId" TEXT,
    "totalAmount" INTEGER NOT NULL,
    "receiverId" TEXT,
    "receiverGross" INTEGER,
    "receiverNet" INTEGER,
    "ownerId" TEXT,
    "ownerGross" INTEGER,
    "ownerNet" INTEGER,
    "siteAmount" INTEGER NOT NULL DEFAULT 0,
    "giftEventId" TEXT,
    "metadata" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "voice_room_finance_audit_log_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "voice_room_finance_audit_log_roomId_createdAt_idx" ON "voice_room_finance_audit_log"("roomId", "createdAt");
CREATE INDEX IF NOT EXISTS "voice_room_finance_audit_log_transactionType_createdAt_idx" ON "voice_room_finance_audit_log"("transactionType", "createdAt");
CREATE INDEX IF NOT EXISTS "voice_room_finance_audit_log_actorId_createdAt_idx" ON "voice_room_finance_audit_log"("actorId", "createdAt");
