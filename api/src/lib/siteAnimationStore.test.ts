import assert from "node:assert/strict";
import { describe, it } from "node:test";
import {
  createSiteAnimation,
  getSiteAnimationStats,
  listActiveSiteAnimations,
  resetSiteAnimationStoreForTests,
} from "./siteAnimationStore";

describe("siteAnimationStore json fallback", () => {
  it("seeds animations when DATABASE_URL is unset", async () => {
    const prev = process.env.DATABASE_URL;
    const prevJson = process.env.SITE_ANIMATION_STORE_JSON;
    delete process.env.DATABASE_URL;
    process.env.SITE_ANIMATION_STORE_JSON = "1";
    await resetSiteAnimationStoreForTests();
    try {
      const active = await listActiveSiteAnimations();
      assert.ok(active.length >= 3);
      const stats = await getSiteAnimationStats();
      assert.ok(stats.total >= stats.active);
      const created = await createSiteAnimation({
        id: "anim_test_temp",
        name: "Test",
        category: "entrance",
        membership: "normal",
      });
      assert.equal(created.id, "anim_test_temp");
    } finally {
      if (prev) process.env.DATABASE_URL = prev;
      else delete process.env.DATABASE_URL;
      if (prevJson) process.env.SITE_ANIMATION_STORE_JSON = prevJson;
      else delete process.env.SITE_ANIMATION_STORE_JSON;
      await resetSiteAnimationStoreForTests();
    }
  });
});
