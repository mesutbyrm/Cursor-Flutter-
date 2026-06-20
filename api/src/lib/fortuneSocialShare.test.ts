import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  buildFortuneShareCaption,
  fortuneTypeLabel,
} from "./fortuneSocialShare.js";

describe("fortuneSocialShare", () => {
  it("builds templated social caption", () => {
    const caption = buildFortuneShareCaption({
      displayName: "Mesut",
      fortuneSlug: "tarot",
      summary: "Enerjin yükseliyor; doğru zamandasın.",
    });
    assert.ok(caption.includes("Mesut bugün Tarot Falı açtı."));
    assert.ok(caption.includes("Yapay zekanın yorumu"));
    assert.ok(caption.includes("Sen de kendi falını şimdi aç."));
  });

  it("resolves fortune type labels", () => {
    assert.equal(fortuneTypeLabel("kahve-fali"), "Kahve Falı");
    assert.equal(fortuneTypeLabel("unknown-slug", "Özel"), "Özel");
  });
});
