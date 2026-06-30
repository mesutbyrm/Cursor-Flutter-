/** Admin / staff yetki çözümlemesi — rol + kullanıcı adı (canlifal.com mobil + admin panel). */

export const STAFF_ROLES = new Set([
  "admin",
  "yonetici",
  "moderator",
  "destek",
  "yardim",
  "super_admin",
  "superadmin",
  "founder",
]);

export const MANAGER_USERNAMES = new Set(["admin", "yonetici"]);

export type StaffUserLike = {
  role: string;
  username?: string | null;
};

/** API yanıtlarında kullanılacak efektif rol (username admin → admin). */
export function effectiveStaffRole(user: StaffUserLike): string {
  const username = user.username?.toLowerCase().trim() ?? "";
  if (username === "admin") return "admin";
  if (username === "yonetici") return "yonetici";
  const role = user.role?.toLowerCase().trim() ?? "user";
  if (STAFF_ROLES.has(role)) return role;
  return role || "user";
}

export function isStaffUser(user: StaffUserLike): boolean {
  const eff = effectiveStaffRole(user);
  if (STAFF_ROLES.has(eff)) return true;
  const u = user.username?.toLowerCase().trim() ?? "";
  return MANAGER_USERNAMES.has(u);
}

const PAYMENT_MANAGER_ROLES = new Set([
  "admin",
  "yonetici",
  "super_admin",
  "superadmin",
  "founder",
]);

/** Ödeme onay/red — admin, yönetici ve üst roller. */
export function isAdminOrManager(user: StaffUserLike): boolean {
  const eff = effectiveStaffRole(user);
  if (PAYMENT_MANAGER_ROLES.has(eff)) return true;
  const u = user.username?.toLowerCase().trim() ?? "";
  return MANAGER_USERNAMES.has(u);
}

export function staffAccessPayload(user: StaffUserLike) {
  const role = effectiveStaffRole(user);
  return {
    role,
    isStaff: isStaffUser(user),
    isAdmin: role === "admin" || user.username?.toLowerCase().trim() === "admin",
    canManagePayments: isAdminOrManager(user),
  };
}
