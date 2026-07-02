import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { cacheGetOrSet } from "./cache";

describe("cacheGetOrSet", () => {
  it("loads once then serves cached value", async () => {
    let loads = 0;
    const loader = async () => {
      loads += 1;
      return { n: 42 };
    };
    const a = await cacheGetOrSet("test:cache:unit", 30, loader);
    const b = await cacheGetOrSet("test:cache:unit", 30, loader);
    assert.equal(a.n, 42);
    assert.equal(b.n, 42);
    assert.equal(loads, 1);
  });
});
