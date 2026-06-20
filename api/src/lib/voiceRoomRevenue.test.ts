import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  calculateGiftSplit,
  calculateMusicSplit,
} from "./voiceRoomRevenue.js";

const baseSettings = {
  giftReceiverPercent: 70,
  roomOwnerPercent: 30,
  siteCommissionPercent: 50,
  musicOwnerPercent: 50,
  musicSitePercent: 50,
  vipMusicOwnerPercent: 70,
  vipMusicSitePercent: 30,
};

describe("calculateGiftSplit", () => {
  it("NORMAL: 1000 jeton — örnek dağılım", () => {
    const s = calculateGiftSplit(1000, "NORMAL", baseSettings);
    assert.equal(s.receiverGross, 700);
    assert.equal(s.ownerGross, 300);
    assert.equal(s.receiverNet, 350);
    assert.equal(s.ownerNet, 150);
    assert.equal(s.siteAmount, 500);
    assert.equal(s.receiverNet + s.ownerNet + s.siteAmount, 1000);
  });

  it("komisyon brüt pay üzerinden — toplam üzerinden değil", () => {
    const s = calculateGiftSplit(1000, "NORMAL", baseSettings);
    assert.equal(s.receiverCommission, 350);
    assert.equal(s.ownerCommission, 150);
    assert.equal(s.receiverCommission + s.ownerCommission, s.siteAmount - 0);
  });

  it("FREE: oda sahibi gelir almaz", () => {
    const s = calculateGiftSplit(1000, "FREE", baseSettings);
    assert.equal(s.ownerGross, 0);
    assert.equal(s.ownerNet, 0);
    assert.equal(s.receiverNet, 350);
    assert.equal(s.siteFromOwnerShare, 300);
    assert.equal(s.receiverNet + s.ownerNet + s.siteAmount, 1000);
  });
});

describe("calculateMusicSplit", () => {
  it("FREE: tamamı site", () => {
    const s = calculateMusicSplit(10, "FREE", baseSettings);
    assert.equal(s.ownerNet, 0);
    assert.equal(s.siteAmount, 10);
  });

  it("NORMAL: 50/50", () => {
    const s = calculateMusicSplit(10, "NORMAL", baseSettings);
    assert.equal(s.ownerNet, 5);
    assert.equal(s.siteAmount, 5);
  });

  it("VIP: 70/30", () => {
    const s = calculateMusicSplit(10, "VIP", baseSettings);
    assert.equal(s.ownerNet, 7);
    assert.equal(s.siteAmount, 3);
  });
});
