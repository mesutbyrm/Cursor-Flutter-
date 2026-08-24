import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  songQueueGetCurrent,
  songQueueGetQueue,
} from "./songQueueService.js";

describe("SongQueueService", () => {
  it("returns empty current song for unknown room", async () => {
    const current = await songQueueGetCurrent("nonexistent-room-test");
    assert.equal(current.videoId, null);
    assert.ok(current.serverTime > 0);
  });

  it("returns empty queue for unknown room", async () => {
    const data = await songQueueGetQueue("nonexistent-room-test");
    assert.deepEqual(data.queue, []);
    assert.ok(data.serverTime > 0);
  });
});
