import assert from "node:assert/strict";
import test from "node:test";
import {
  effectiveStaffRole,
  isAdminOrManager,
  isStaffUser,
  staffAccessPayload,
} from "./staffAccess";

test("effectiveStaffRole promotes username admin to admin", () => {
  assert.equal(
    effectiveStaffRole({ role: "user", username: "admin" }),
    "admin",
  );
  assert.equal(
    effectiveStaffRole({ role: "user", username: "Admin" }),
    "admin",
  );
  assert.equal(
    effectiveStaffRole({ role: "user", username: "yonetim" }),
    "yonetici",
  );
});

test("isStaffUser accepts admin username without DB role", () => {
  assert.equal(isStaffUser({ role: "user", username: "admin" }), true);
  assert.equal(isStaffUser({ role: "moderator", username: "ali" }), true);
  assert.equal(isStaffUser({ role: "user", username: "ali" }), false);
});

test("isAdminOrManager includes admin username and super_admin role", () => {
  assert.equal(isAdminOrManager({ role: "user", username: "admin" }), true);
  assert.equal(isAdminOrManager({ role: "super_admin", username: "x" }), true);
  assert.equal(isAdminOrManager({ role: "moderator", username: "mod1" }), false);
});

test("staffAccessPayload exposes payment flags for admin username", () => {
  const payload = staffAccessPayload({ role: "user", username: "admin" });
  assert.equal(payload.role, "admin");
  assert.equal(payload.isStaff, true);
  assert.equal(payload.isAdmin, true);
  assert.equal(payload.canManagePayments, true);
});
