import { describe, it, beforeEach, afterEach } from "node:test";
import assert from "node:assert/strict";
import {
  sweepStaleRoomPresence,
  touchPresenceHeartbeat,
  listPresence,
  leavePresence,
  seedPresenceRow,
} from "./chatRoomStore.js";

const roomId = "room-1";

describe("chatRoomStore presence ghost sweep", () => {
  beforeEach(() => {
    leavePresence(roomId, "ghost-1");
    leavePresence(roomId, "alive-1");
  });

  afterEach(() => {
    leavePresence(roomId, "ghost-1");
    leavePresence(roomId, "alive-1");
  });

  it("removes users without recent heartbeat", () => {
    const joinedAt = Date.now();
    seedPresenceRow(roomId, {
      id: "ghost-1",
      name: "Ghost",
      joinedAt,
      lastHeartbeatAt: joinedAt,
    });
    assert.equal(listPresence(roomId).length, 1);

    const removed = sweepStaleRoomPresence(roomId, joinedAt + 50_000);
    assert.equal(removed.length, 1);
    assert.equal(removed[0]!.userId, "ghost-1");
    assert.equal(listPresence(roomId).length, 0);
  });

  it("keeps users with fresh heartbeat", () => {
    seedPresenceRow(roomId, {
      id: "alive-1",
      name: "Alive",
      joinedAt: Date.now(),
      lastHeartbeatAt: Date.now(),
    });
    touchPresenceHeartbeat(roomId, "alive-1");
    const removed = sweepStaleRoomPresence(roomId);
    assert.equal(removed.length, 0);
    assert.equal(listPresence(roomId).length, 1);
  });
});
