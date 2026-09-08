import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { buildSiteAnimationRoomEvent } from "./siteAnimationResolver";
import {
  resetSiteAnimationStoreForTests,
  saveSiteAnimationExitDefaults,
  updateSiteAnimation,
} from "./siteAnimationStore";

describe("siteAnimationResolver", () => {
  it("returns active gold entrance animation metadata", async () => {
    process.env.SITE_ANIMATION_STORE_JSON = "1";
    delete process.env.DATABASE_URL;
    await resetSiteAnimationStoreForTests();
    const payload = await buildSiteAnimationRoomEvent({
      event: "user_joined",
      userId: "u-gold",
      name: "Altın Üye",
      membership: "gold",
    });
    assert.ok(payload);
    assert.equal(payload?.event, "user_joined");
    const animation = payload?.animation as Record<string, unknown>;
    assert.equal(animation.id, "anim_entrance_gold_crown");
    assert.equal(animation.assetUrl, "assets/gifts/lottie/crown.json");
  });

  it("returns null when resolved animation is passive", async () => {
    process.env.SITE_ANIMATION_STORE_JSON = "1";
    delete process.env.DATABASE_URL;
    await resetSiteAnimationStoreForTests();
    await updateSiteAnimation("anim_entrance_gold_crown", { isActive: false });
    const payload = await buildSiteAnimationRoomEvent({
      event: "user_joined",
      userId: "u-passive",
      membership: "gold",
    });
    assert.equal(payload, null);
  });

  it("resolves exit defaults by membership", async () => {
    process.env.SITE_ANIMATION_STORE_JSON = "1";
    delete process.env.DATABASE_URL;
    await resetSiteAnimationStoreForTests();
    const payload = await buildSiteAnimationRoomEvent({
      event: "user_left",
      userId: "u-exit",
      membership: "gold",
      name: "Ayrılan",
    });
    const animation = payload?.animation as Record<string, unknown>;
    assert.equal(animation.id, "anim_exit_gold");
  });

  it("resolves seat_changed transition animation", async () => {
    process.env.SITE_ANIMATION_STORE_JSON = "1";
    delete process.env.DATABASE_URL;
    await resetSiteAnimationStoreForTests();
    const payload = await buildSiteAnimationRoomEvent({
      event: "seat_changed",
      userId: "u-seat",
      membership: "gold",
      seatIndex: 3,
      previousSeatIndex: 1,
    });
    const animation = payload?.animation as Record<string, unknown>;
    assert.equal(animation.id, "anim_transition_seat_change");
  });

  it("uses saved exit defaults", async () => {
    process.env.SITE_ANIMATION_STORE_JSON = "1";
    delete process.env.DATABASE_URL;
    await resetSiteAnimationStoreForTests();
    await saveSiteAnimationExitDefaults({
      gold: "anim_exit_premium",
    });
    const payload = await buildSiteAnimationRoomEvent({
      event: "user_left",
      userId: "u-exit-custom",
      membership: "gold",
    });
    const animation = payload?.animation as Record<string, unknown>;
    assert.equal(animation.id, "anim_exit_premium");
  });

  it("resolves mic_changed mic on/off animations", async () => {
    process.env.SITE_ANIMATION_STORE_JSON = "1";
    delete process.env.DATABASE_URL;
    await resetSiteAnimationStoreForTests();
    const on = await buildSiteAnimationRoomEvent({
      event: "mic_changed",
      userId: "u-mic",
      membership: "gold",
      micOn: true,
      seatIndex: 2,
    });
    const off = await buildSiteAnimationRoomEvent({
      event: "mic_changed",
      userId: "u-mic",
      membership: "gold",
      micOn: false,
      seatIndex: 2,
    });
    assert.equal((on?.animation as Record<string, unknown>).id, "anim_mic_on");
    assert.equal((off?.animation as Record<string, unknown>).id, "anim_mic_off");
  });
});
