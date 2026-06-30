import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { describe, it } from "node:test";
import { resolveStreamViaYtdlp } from "./ytdlpStreamResolver.js";

function ytDlpAvailable(): boolean {
  try {
    execFileSync("yt-dlp", ["--version"], { stdio: "pipe" });
    return true;
  } catch {
    return false;
  }
}

describe("resolveStreamViaYtdlp", () => {
  it("returns null when yt-dlp is missing", async () => {
    if (ytDlpAvailable()) return;
    const url = await resolveStreamViaYtdlp("dQw4w9WgXcQ");
    assert.equal(url, null);
  });

  it("resolves googlevideo audio URL for Rick Astley video", async (t) => {
    if (!ytDlpAvailable()) {
      t.skip("yt-dlp not installed");
      return;
    }
    const url = await resolveStreamViaYtdlp(
      "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
    );
    assert.ok(url);
    assert.match(url!, /^https:\/\//);
    assert.match(url!, /googlevideo\.com|mime=audio/);
  });
});
