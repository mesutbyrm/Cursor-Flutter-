/** canlifal.com sesli oda nick önekleri — founder > sop > op > admin */
export type VoiceStaffRank = "founder" | "sop" | "op" | "admin" | "none";

export function parseStaffRank(
  username: string | null | undefined,
  role?: string | null,
): VoiceStaffRank {
  const n = (username ?? "").trim();
  if (n.startsWith("~")) return "founder";
  if (n.startsWith("&")) return "sop";
  if (n.startsWith("@")) return "op";
  if (n.startsWith("%")) return "admin";
  const lower = n.toLowerCase();
  if (lower === "admin" || lower === "destek" || lower === "moderator" || lower === "yonetici") {
    return "admin";
  }
  const r = (role ?? "").toLowerCase();
  if (r === "founder" || r === "superadmin") return "founder";
  if (r === "sop") return "sop";
  if (r === "op" || r === "moderator") return "op";
  if (r === "admin") return "admin";
  return "none";
}

export function rankPower(rank: VoiceStaffRank): number {
  switch (rank) {
    case "founder":
      return 100;
    case "sop":
      return 80;
    case "op":
      return 60;
    case "admin":
      return 50;
    default:
      return 0;
  }
}

export function rankSymbol(rank: VoiceStaffRank): string | null {
  switch (rank) {
    case "founder":
      return "~";
    case "sop":
      return "&";
    case "op":
      return "@";
    case "admin":
      return "%";
    default:
      return null;
  }
}

export function canModerateRank(rank: VoiceStaffRank): boolean {
  return rankPower(rank) >= rankPower("op");
}

export function fullControlRank(rank: VoiceStaffRank): boolean {
  return rankPower(rank) >= rankPower("admin");
}
