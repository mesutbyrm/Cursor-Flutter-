import { prisma } from "./prisma";
import { SITE_ANIMATION_DEFAULTS, SITE_ANIMATION_SEED } from "./siteAnimationSeed";

/** İlk açılışta site animasyon tablolarını seed eder (idempotent). */
export async function bootstrapSiteAnimations(): Promise<void> {
  if (!process.env.DATABASE_URL) return;

  try {
    const count = await prisma.siteAnimation.count();
    if (count === 0) {
      for (const item of SITE_ANIMATION_SEED) {
        await prisma.siteAnimation.create({
          data: {
            id: item.id,
            name: item.name,
            category: item.category,
            membership: item.membership,
            animationType: item.animationType,
            assetUrl: item.assetUrl ?? null,
            previewUrl: item.previewUrl ?? null,
            soundUrl: item.soundUrl ?? null,
            durationMs: item.durationMs,
            priority: item.priority,
            rarity: item.rarity,
            context: item.context,
            anchor: item.anchor,
            scale: item.scale,
            cooldownMs: item.cooldownMs,
            isActive: item.isActive,
            description: item.description ?? null,
            previewMp4Key: item.previewMp4Key ?? null,
          },
        });
      }
    }

    for (const [membership, animationId] of Object.entries(SITE_ANIMATION_DEFAULTS)) {
      await prisma.siteAnimationDefault.upsert({
        where: { membership },
        create: { membership, animationId },
        update: { animationId },
      });
    }
  } catch (e) {
    console.warn("[site-animation] bootstrap skipped:", e);
  }
}
