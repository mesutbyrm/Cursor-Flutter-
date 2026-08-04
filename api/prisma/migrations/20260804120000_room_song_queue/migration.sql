-- CreateTable
CREATE TABLE "room_song_queue" (
    "id" TEXT NOT NULL,
    "roomId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "username" TEXT,
    "videoId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "thumbnail" TEXT,
    "duration" TEXT,
    "channel" TEXT,
    "status" TEXT NOT NULL DEFAULT 'queued',
    "position" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "room_song_queue_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "room_current_song" (
    "id" TEXT NOT NULL,
    "roomId" TEXT NOT NULL,
    "queueId" TEXT,
    "videoId" TEXT,
    "title" TEXT,
    "thumbnail" TEXT,
    "durationSec" INTEGER,
    "channel" TEXT,
    "ownerId" TEXT,
    "ownerName" TEXT,
    "startedAt" TIMESTAMP(3),
    "pausedAt" TIMESTAMP(3),
    "paused" BOOLEAN NOT NULL DEFAULT false,
    "elapsedMs" INTEGER NOT NULL DEFAULT 0,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "room_current_song_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "room_song_history" (
    "id" TEXT NOT NULL,
    "roomId" TEXT NOT NULL,
    "queueId" TEXT,
    "videoId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "thumbnail" TEXT,
    "durationSec" INTEGER,
    "channel" TEXT,
    "requestedById" TEXT NOT NULL,
    "requestedBy" TEXT,
    "playCount" INTEGER NOT NULL DEFAULT 1,
    "playedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "finishedAt" TIMESTAMP(3),
    "skipped" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "room_song_history_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "room_song_queue_roomId_status_position_idx" ON "room_song_queue"("roomId", "status", "position");

-- CreateIndex
CREATE UNIQUE INDEX "room_current_song_roomId_key" ON "room_current_song"("roomId");

-- CreateIndex
CREATE INDEX "room_song_history_roomId_playedAt_idx" ON "room_song_history"("roomId", "playedAt");

-- CreateIndex
CREATE INDEX "room_song_history_videoId_idx" ON "room_song_history"("videoId");
