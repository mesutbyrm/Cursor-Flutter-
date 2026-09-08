import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  addFortuneSessionTip,
  createFortuneSession,
  fortuneSessionRoomPayload,
  getTellerOnlineStatus,
  listActiveFortuneSessionsForUser,
  patchFortuneSessionRoom,
  saveFortuneSessionReview,
  setTellerOnlineStatus,
} from "./liveStreamExtrasStore.js";

describe("fortuneRoomStore", () => {
  it("tracks teller online toggle", () => {
    const uid = "teller-online-test";
    assert.equal(getTellerOnlineStatus(uid), false);
    setTellerOnlineStatus(uid, true);
    assert.equal(getTellerOnlineStatus(uid), true);
  });

  it("builds room payload with timer and role", () => {
    const session = createFortuneSession("teller-1", "client-1", "teller-user-1", {
      clientName: "Ali",
      durationMinutes: 10,
      totalJeton: 50,
    });
    const patched = patchFortuneSessionRoom(session.id, "teller-user-1", "start_timer");
    assert.equal(patched.ok, true);
    if (!patched.ok) return;

    const payload = fortuneSessionRoomPayload(patched.session, "client-1");
    assert.equal(payload.role, "client");
    assert.equal(payload.isClient, true);
    assert.equal(payload.timerStarted, true);
    assert.equal(payload.remainingSeconds <= 600, true);
  });

  it("adds tips and reviews for client only", () => {
    const session = createFortuneSession("teller-2", "client-2", "teller-user-2");
    const tip = addFortuneSessionTip(session.id, "client-2", 25);
    assert.equal(tip.ok, true);
    if (tip.ok) assert.equal(tip.tipsTotal, 25);

    const denied = addFortuneSessionTip(session.id, "teller-user-2", 10);
    assert.equal(denied.ok, false);

    const review = saveFortuneSessionReview(session.id, "client-2", 5, "Harika");
    assert.equal(review.ok, true);
    if (review.ok) assert.equal(review.review.rating, 5);
  });

  it("lists active sessions for participant", () => {
    const session = createFortuneSession("teller-3", "client-3", "teller-user-3");
    patchFortuneSessionRoom(session.id, "teller-user-3", "start_timer");
    const active = listActiveFortuneSessionsForUser("client-3");
    assert.ok(active.some((s) => s.id === session.id));
  });
});
