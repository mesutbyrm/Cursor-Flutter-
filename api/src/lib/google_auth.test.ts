import assert from "node:assert/strict";
import test from "node:test";
import {
  googleAllowedClientIds,
  isGoogleAudienceAllowed,
} from "./google_auth";

test("googleAllowedClientIds merges GOOGLE_CLIENT_ID and GOOGLE_SERVER_CLIENT_ID", () => {
  const prevClient = process.env.GOOGLE_CLIENT_ID;
  const prevServer = process.env.GOOGLE_SERVER_CLIENT_ID;
  process.env.GOOGLE_CLIENT_ID = "web-client.apps.googleusercontent.com";
  process.env.GOOGLE_SERVER_CLIENT_ID =
    "web-client.apps.googleusercontent.com";
  process.env.GOOGLE_CLIENT_IDS =
    "android-client.apps.googleusercontent.com, android-client.apps.googleusercontent.com";
  try {
    assert.deepEqual(googleAllowedClientIds(), [
      "web-client.apps.googleusercontent.com",
      "android-client.apps.googleusercontent.com",
    ]);
  } finally {
    process.env.GOOGLE_CLIENT_ID = prevClient;
    process.env.GOOGLE_SERVER_CLIENT_ID = prevServer;
    delete process.env.GOOGLE_CLIENT_IDS;
  }
});

test("isGoogleAudienceAllowed accepts aud or azp", () => {
  const allowed = ["web.apps.googleusercontent.com"];
  assert.equal(
    isGoogleAudienceAllowed(
      { aud: "web.apps.googleusercontent.com" },
      allowed,
    ),
    true,
  );
  assert.equal(
    isGoogleAudienceAllowed(
      { aud: "other.apps.googleusercontent.com", azp: "web.apps.googleusercontent.com" },
      allowed,
    ),
    true,
  );
  assert.equal(
    isGoogleAudienceAllowed(
      { aud: "wrong.apps.googleusercontent.com" },
      allowed,
    ),
    false,
  );
  assert.equal(isGoogleAudienceAllowed({ aud: "any" }, []), true);
});
