import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  parseFortuneAction,
  parseFortuneCreateBody,
  resolveFortuneTypeId,
} from "./streamFortuneRequestService.js";

describe("streamFortuneRequestService", () => {
  it("resolves production typeId", () => {
    assert.equal(resolveFortuneTypeId("tek-soru"), "tek-soru");
    assert.equal(resolveFortuneTypeId("tarot"), "tek-soru");
    assert.equal(resolveFortuneTypeId("invalid-xyz"), null);
  });

  it("parses production body", () => {
    const r = parseFortuneCreateBody({
      typeId: "tek-soru",
      nickname: "Test",
      question: "Uzun bir fal sorusu?",
      isHidden: false,
    });
    assert.equal(r.ok, true);
    if (r.ok) {
      assert.equal(r.data.typeId, "tek-soru");
      assert.equal(r.data.jetonAmount, 5);
    }
  });

  it("parses legacy body without 500 path", () => {
    const r = parseFortuneCreateBody({
      displayName: "Legacy",
      question: "Legacy fal sorusu uzun mu?",
      fortuneType: "tarot",
      priority: "standard",
      jetonCost: 50,
    });
    assert.equal(r.ok, true);
    if (r.ok) {
      assert.equal(r.data.typeId, "tek-soru");
      assert.equal(r.data.nickname, "Legacy");
    }
  });

  it("rejects invalid legacy fortuneType", () => {
    const r = parseFortuneCreateBody({
      displayName: "Bad",
      question: "Geçersiz tür sorusu?",
      fortuneType: "not-a-real-type",
    });
    assert.equal(r.ok, false);
    if (!r.ok) assert.equal(r.error.code, "INVALID_TYPE");
  });

  it("parses fortune actions", () => {
    assert.deepEqual(parseFortuneAction({ action: "select", requestId: "abc" }), {
      action: "select",
      requestId: "abc",
    });
    assert.equal(parseFortuneAction({ action: "nope", requestId: "abc" }), null);
  });
});
