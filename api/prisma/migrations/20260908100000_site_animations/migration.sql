-- Site animation library (voice room overlays)
CREATE TABLE "site_animations" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "membership" TEXT NOT NULL DEFAULT 'normal',
    "animation_type" TEXT NOT NULL DEFAULT 'native',
    "asset_url" TEXT,
    "preview_url" TEXT,
    "sound_url" TEXT,
    "duration_ms" INTEGER NOT NULL DEFAULT 3000,
    "priority" INTEGER NOT NULL DEFAULT 50,
    "rarity" TEXT NOT NULL DEFAULT 'common',
    "context" TEXT NOT NULL DEFAULT 'voice_room',
    "anchor" TEXT NOT NULL DEFAULT 'TOP_LEFT',
    "scale" DOUBLE PRECISION NOT NULL DEFAULT 1,
    "cooldown_ms" INTEGER NOT NULL DEFAULT 0,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "description" TEXT,
    "preview_mp4_key" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "site_animations_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "site_animations_category_membership_is_active_idx"
ON "site_animations"("category", "membership", "is_active");

CREATE TABLE "site_animation_defaults" (
    "id" TEXT NOT NULL,
    "membership" TEXT NOT NULL,
    "animation_id" TEXT NOT NULL,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "site_animation_defaults_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "site_animation_defaults_membership_key"
ON "site_animation_defaults"("membership");

ALTER TABLE "site_animation_defaults"
ADD CONSTRAINT "site_animation_defaults_animation_id_fkey"
FOREIGN KEY ("animation_id") REFERENCES "site_animations"("id")
ON DELETE RESTRICT ON UPDATE CASCADE;

CREATE TABLE "site_animation_user_assignments" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "slot" TEXT NOT NULL,
    "animation_id" TEXT,
    "expires_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "site_animation_user_assignments_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "site_animation_user_assignments_user_id_slot_key"
ON "site_animation_user_assignments"("user_id", "slot");

CREATE INDEX "site_animation_user_assignments_user_id_idx"
ON "site_animation_user_assignments"("user_id");

ALTER TABLE "site_animation_user_assignments"
ADD CONSTRAINT "site_animation_user_assignments_animation_id_fkey"
FOREIGN KEY ("animation_id") REFERENCES "site_animations"("id")
ON DELETE SET NULL ON UPDATE CASCADE;
