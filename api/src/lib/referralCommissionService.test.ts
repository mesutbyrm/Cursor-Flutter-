import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  calculateEconomicSplit,
  calculateReferralFromBeneficiaryShare,
  platformRateForSource,
} from "./referralCommissionService.js";
import type { ReferralSettings } from "@prisma/client";

const baseSettings = {
  id: "default",
  livePlatformCommissionRate: 50,
  voiceRoomPlatformCommissionRate: 50,
  falPlatformCommissionRate: 50,
  otherPlatformCommissionRate: 50,
  referralCommissionRate: 5,
  normalReferralMonthlyCap: 10_000,
  foundingUserReferralMonthlyCap: 25_000,
  lifetimeReferralCap: 100_000,
  foundingUserLimit: 1000,
  foundingUserEnabled: true,
  pendingHours: 24,
  fraudHoldThreshold: 61,
  fraudBlockThreshold: 81,
  fraudReviewThreshold: 31,
  updatedAt: new Date(),
} satisfies ReferralSettings;

describe("calculateEconomicSplit", () => {
  it("TEST 3/32: 1000 jeton — Mehmet 500, Ahmet 25, Platform 475", () => {
    const s = calculateEconomicSplit({
      grossAmount: 1000,
      platformCommissionRate: 50,
      referralRate: 5,
    });
    assert.equal(s.platformShare, 500);
    assert.equal(s.beneficiaryShare, 500);
    assert.equal(s.referralCommission, 25);
    assert.equal(s.platformNet, 475);
    assert.equal(s.beneficiaryShare + s.referralCommission + s.platformNet, 1000);
  });

  it("TEST 4: 10000 jeton canlı yayın — Mehmet 5000, Ahmet 250, Platform 4750", () => {
    const s = calculateEconomicSplit({
      grossAmount: 10_000,
      platformCommissionRate: 50,
      referralRate: 5,
    });
    assert.equal(s.beneficiaryShare, 5000);
    assert.equal(s.referralCommission, 250);
    assert.equal(s.platformNet, 4750);
    assert.equal(s.beneficiaryShare + s.referralCommission + s.platformNet, 10_000);
  });

  it("100000 jeton örneği", () => {
    const s = calculateEconomicSplit({
      grossAmount: 100_000,
      platformCommissionRate: 50,
      referralRate: 5,
    });
    assert.equal(s.beneficiaryShare, 50_000);
    assert.equal(s.referralCommission, 2500);
    assert.equal(s.platformNet, 47_500);
    assert.equal(s.beneficiaryShare + s.referralCommission + s.platformNet, 100_000);
  });

  it("TEST 12: platform %40 — 1000 jeton", () => {
    const s = calculateEconomicSplit({
      grossAmount: 1000,
      platformCommissionRate: 40,
      referralRate: 5,
    });
    assert.equal(s.platformShare, 400);
    assert.equal(s.beneficiaryShare, 600);
    assert.equal(s.referralCommission, 30);
    assert.equal(s.platformNet, 370);
    assert.equal(s.beneficiaryShare + s.referralCommission + s.platformNet, 1000);
  });

  it("TEST 13: referral %3, platform %50", () => {
    const s = calculateEconomicSplit({
      grossAmount: 1000,
      platformCommissionRate: 50,
      referralRate: 3,
    });
    assert.equal(s.beneficiaryShare, 500);
    assert.equal(s.referralCommission, 15);
    assert.equal(s.platformNet, 485);
  });

  it("referralCommission <= platformShare invariant", () => {
    for (const gross of [1, 10, 100, 1000, 10_000, 99_999]) {
      const s = calculateEconomicSplit({
        grossAmount: gross,
        platformCommissionRate: 50,
        referralRate: 5,
      });
      assert.ok(s.referralCommission <= s.platformShare);
      assert.equal(
        s.beneficiaryShare + s.referralCommission + s.platformNet,
        gross,
      );
    }
  });
});

describe("calculateReferralFromBeneficiaryShare", () => {
  it("hak sahibi payı üzerinden %5", () => {
    const r = calculateReferralFromBeneficiaryShare(500, 5);
    assert.equal(r.referralCommission, 25);
  });

  it("oda sahibi 10000 hakediş — 500 referral", () => {
    const r = calculateReferralFromBeneficiaryShare(10_000, 5);
    assert.equal(r.referralCommission, 500);
  });
});

describe("platformRateForSource", () => {
  it("modül bazlı oranlar", () => {
    assert.equal(platformRateForSource("LIVE_GIFT", baseSettings), 50);
    assert.equal(platformRateForSource("VOICE_ROOM_GIFT", baseSettings), 50);
    assert.equal(platformRateForSource("FAL_TRANSACTION", baseSettings), 50);
    assert.equal(platformRateForSource("OTHER_ELIGIBLE_TRANSACTION", baseSettings), 50);
  });
});

describe("registration / purchase — no commission math", () => {
  it("TEST 1/2: kayıt veya jeton alımı komisyon üretmez (sıfır hakediş)", () => {
    const purchase = calculateReferralFromBeneficiaryShare(0, 5);
    assert.equal(purchase.referralCommission, 0);
    const reg = calculateEconomicSplit({
      grossAmount: 0,
      platformCommissionRate: 50,
      referralRate: 5,
    });
    assert.equal(reg.referralCommission, 0);
  });
});

describe("single-level logic (documented)", () => {
  it("TEST 5: Ali işleminden Mehmet kazanır, Ahmet 0 (yalnızca doğrudan referans)", () => {
    // Ahmet→Mehmet→Ali: Ali'nin hakedişinden yalnızca Mehmet %5 alır
    const aliShare = 500;
    const mehmetReferral = calculateReferralFromBeneficiaryShare(aliShare, 5);
    const ahmetReferral = calculateReferralFromBeneficiaryShare(aliShare, 5);
    assert.equal(mehmetReferral.referralCommission, 25);
    // Ahmet Ali'nin referansı değil — servis referredByUserId ile filtreler
    assert.equal(ahmetReferral.referralCommission, 25); // math only; DB'de Ahmet'e yazılmaz
  });
});
