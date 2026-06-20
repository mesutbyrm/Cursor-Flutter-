-- Premium AI fal deneyimi: genişletilmiş fal kaydı + sosyal fal paylaşımı
ALTER TABLE "UserFortune" ADD COLUMN IF NOT EXISTS "imageUrl" TEXT;
ALTER TABLE "UserFortune" ADD COLUMN IF NOT EXISTS "fortuneText" TEXT;
ALTER TABLE "UserFortune" ADD COLUMN IF NOT EXISTS "visualAnalysis" TEXT;
ALTER TABLE "UserFortune" ADD COLUMN IF NOT EXISTS "likesCount" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "UserFortune" ADD COLUMN IF NOT EXISTS "commentsCount" INTEGER NOT NULL DEFAULT 0;

ALTER TABLE "SocialPost" ADD COLUMN IF NOT EXISTS "fortuneId" TEXT;
CREATE INDEX IF NOT EXISTS "SocialPost_fortuneId_idx" ON "SocialPost"("fortuneId");

CREATE TABLE IF NOT EXISTS "SocialFortunePost" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "fortuneId" TEXT NOT NULL,
    "postId" TEXT,
    "postText" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "SocialFortunePost_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "SocialFortunePost_postId_key" ON "SocialFortunePost"("postId");
CREATE INDEX IF NOT EXISTS "SocialFortunePost_userId_createdAt_idx" ON "SocialFortunePost"("userId", "createdAt");
CREATE INDEX IF NOT EXISTS "SocialFortunePost_fortuneId_idx" ON "SocialFortunePost"("fortuneId");

DO $$ BEGIN
  ALTER TABLE "SocialFortunePost" ADD CONSTRAINT "SocialFortunePost_fortuneId_fkey"
    FOREIGN KEY ("fortuneId") REFERENCES "UserFortune"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE "SocialFortunePost" ADD CONSTRAINT "SocialFortunePost_postId_fkey"
    FOREIGN KEY ("postId") REFERENCES "SocialPost"("id") ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
