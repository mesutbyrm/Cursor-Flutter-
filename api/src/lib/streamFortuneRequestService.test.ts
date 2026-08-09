import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  mapFortuneCreateException,
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

  it("rejects missing nickname", () => {
    const r = parseFortuneCreateBody({
      typeId: "tek-soru",
      question: "Nickname eksik test sorusu?",
      isHidden: false,
    });
    assert.equal(r.ok, false);
    if (!r.ok) assert.equal(r.error.code, "VALIDATION");
  });

  it("rejects short question", () => {
    const r = parseFortuneCreateBody({
      typeId: "tek-soru",
      nickname: "Test",
      question: "kısa",
      isHidden: false,
    });
    assert.equal(r.ok, false);
    if (!r.ok) assert.equal(r.error.code, "VALIDATION");
  });

  it("accepts message alias for question", () => {
    const r = parseFortuneCreateBody({
      typeId: "tek-soru",
      nickname: "Alias",
      message: "Message alanı ile uzun fal sorusu?",
      isHidden: false,
    });
    assert.equal(r.ok, true);
    if (r.ok) assert.equal(r.data.question, "Message alanı ile uzun fal sorusu?");
  });

  it("rejects empty typeId and fortuneType", () => {
    const r = parseFortuneCreateBody({
      displayName: "NoType",
      question: "Tür belirtilmemiş uzun soru?",
    });
    assert.equal(r.ok, false);
    if (!r.ok) assert.equal(r.error.code, "INVALID_TYPE");
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

  it("maps Prisma P2002 to 409", () => {
    const r = mapFortuneCreateException({ code: "P2002" });
    assert.equal(r.status, 409);
    assert.equal(r.code, "CONFLICT");
  });

  it("maps Prisma P2003 to 400 invalid reference", () => {
    const r = mapFortuneCreateException({ code: "P2003" });
    assert.equal(r.status, 400);
    assert.equal(r.code, "INVALID_REFERENCE");
  });

  it("maps unknown errors to 500", () => {
    const r = mapFortuneCreateException(new Error("unexpected"));
    assert.equal(r.status, 500);
  });

  it("parses fortune actions", () => {
    assert.deepEqual(parseFortuneAction({ action: "select", requestId: "abc" }), {
      action: "select",
      requestId: "abc",
    });
    assert.equal(parseFortuneAction({ action: "nope", requestId: "abc" }), null);
  });
});
