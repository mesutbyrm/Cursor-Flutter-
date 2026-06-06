-- PK Battle system tables
CREATE TABLE "PKBattle" (
    "id" TEXT NOT NULL,
    "battleType" TEXT NOT NULL,
    "voiceRoomId" TEXT,
    "opponentVoiceRoomId" TEXT,
    "liveStreamId" TEXT,
    "opponentLiveStreamId" TEXT,
    "challengerId" TEXT NOT NULL,
    "opponentId" TEXT,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "startTime" TIMESTAMP(3),
    "endTime" TIMESTAMP(3),
    "winnerId" TEXT,
    "challengerScore" INTEGER NOT NULL DEFAULT 0,
    "opponentScore" INTEGER NOT NULL DEFAULT 0,
    "durationSeconds" INTEGER NOT NULL DEFAULT 300,
    "targetScore" INTEGER NOT NULL DEFAULT 150000,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "PKBattle_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "PKParticipant" (
    "id" TEXT NOT NULL,
    "battleId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "side" TEXT NOT NULL,
    "roomId" TEXT,
    "streamId" TEXT,
    "score" INTEGER NOT NULL DEFAULT 0,
    "winStreak" INTEGER NOT NULL DEFAULT 0,
    "displayName" TEXT,
    "avatarUrl" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PKParticipant_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "PKGift" (
    "id" TEXT NOT NULL,
    "battleId" TEXT NOT NULL,
    "giftEventId" TEXT,
    "senderId" TEXT,
    "senderName" TEXT NOT NULL,
    "side" TEXT NOT NULL,
    "giftSlug" TEXT NOT NULL,
    "giftName" TEXT,
    "quantity" INTEGER NOT NULL DEFAULT 1,
    "points" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PKGift_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "PKResult" (
    "id" TEXT NOT NULL,
    "battleId" TEXT NOT NULL,
    "winnerId" TEXT,
    "winnerSide" TEXT,
    "challengerFinalScore" INTEGER NOT NULL,
    "opponentFinalScore" INTEGER NOT NULL,
    "championBadge" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PKResult_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "PKParticipant_battleId_side_key" ON "PKParticipant"("battleId", "side");
CREATE UNIQUE INDEX "PKResult_battleId_key" ON "PKResult"("battleId");

CREATE INDEX "PKBattle_battleType_status_idx" ON "PKBattle"("battleType", "status");
CREATE INDEX "PKBattle_voiceRoomId_status_idx" ON "PKBattle"("voiceRoomId", "status");
CREATE INDEX "PKBattle_opponentVoiceRoomId_status_idx" ON "PKBattle"("opponentVoiceRoomId", "status");
CREATE INDEX "PKBattle_liveStreamId_status_idx" ON "PKBattle"("liveStreamId", "status");
CREATE INDEX "PKBattle_opponentLiveStreamId_status_idx" ON "PKBattle"("opponentLiveStreamId", "status");
CREATE INDEX "PKBattle_challengerId_createdAt_idx" ON "PKBattle"("challengerId", "createdAt");
CREATE INDEX "PKBattle_opponentId_createdAt_idx" ON "PKBattle"("opponentId", "createdAt");
CREATE INDEX "PKParticipant_userId_idx" ON "PKParticipant"("userId");
CREATE INDEX "PKParticipant_roomId_idx" ON "PKParticipant"("roomId");
CREATE INDEX "PKParticipant_streamId_idx" ON "PKParticipant"("streamId");
CREATE INDEX "PKGift_battleId_createdAt_idx" ON "PKGift"("battleId", "createdAt");
CREATE INDEX "PKGift_senderId_createdAt_idx" ON "PKGift"("senderId", "createdAt");
CREATE INDEX "PKResult_winnerId_createdAt_idx" ON "PKResult"("winnerId", "createdAt");

ALTER TABLE "PKParticipant" ADD CONSTRAINT "PKParticipant_battleId_fkey" FOREIGN KEY ("battleId") REFERENCES "PKBattle"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "PKGift" ADD CONSTRAINT "PKGift_battleId_fkey" FOREIGN KEY ("battleId") REFERENCES "PKBattle"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "PKResult" ADD CONSTRAINT "PKResult_battleId_fkey" FOREIGN KEY ("battleId") REFERENCES "PKBattle"("id") ON DELETE CASCADE ON UPDATE CASCADE;
