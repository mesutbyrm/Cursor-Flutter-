/**
 * Canlı yayın fal isteği — üretim sözleşmesi + legacy body uyumluluğu.
 * Production: typeId + nickname + question + isHidden
 * Legacy: displayName + fortuneType + priority + jetonCost
 */

export type FortuneRequestTypeRow = {
  id: string;
  name: string;
  nameEn: string;
  jetonCost: number;
  isActive: boolean;
};

/** Üretim katalog — GET /api/fortune-request-types ile aynı kimlikler. */
export const FORTUNE_REQUEST_TYPES: FortuneRequestTypeRow[] = [
  {
    id: "tek-soru",
    name: "Tek Soru",
    nameEn: "Single Question",
    jetonCost: 5,
    isActive: true,
  },
  {
    id: "evet-hayır",
    name: "Evet/Hayır",
    nameEn: "Yes/No",
    jetonCost: 10,
    isActive: true,
  },
  {
    id: "detaylı-fal",
    name: "Detaylı Fal",
    nameEn: "Detailed Reading",
    jetonCost: 50,
    isActive: true,
  },
];

export type ParsedFortuneCreateBody = {
  typeId: string;
  nickname: string;
  question: string;
  isHidden: boolean;
  jetonAmount: number;
};

export type FortuneCreateError =
  | { code: "VALIDATION"; message: string }
  | { code: "INVALID_TYPE"; message: string }
  | { code: "PENDING_EXISTS"; message: string };

const LEGACY_TYPE_MAP: Record<string, string> = {
  tarot: "tek-soru",
  coffee: "detaylı-fal",
  astrology: "tek-soru",
  palmistry: "detaylı-fal",
  numerology: "tek-soru",
  general: "tek-soru",
  "evet-hayir": "evet-hayır",
  "detayli-fal": "detaylı-fal",
};

export function resolveFortuneTypeId(raw: string | undefined): string | null {
  const v = raw?.trim() ?? "";
  if (!v) return null;
  if (FORTUNE_REQUEST_TYPES.some((t) => t.id === v)) return v;
  const mapped = LEGACY_TYPE_MAP[v.toLowerCase()];
  if (mapped) return mapped;
  return null;
}

export function getFortuneType(typeId: string): FortuneRequestTypeRow | null {
  return FORTUNE_REQUEST_TYPES.find((t) => t.id === typeId && t.isActive) ?? null;
}

/** Legacy + üretim gövdesini tek forma indirger; 500 yerine doğrulama hatası döner. */
export function parseFortuneCreateBody(
  body: Record<string, unknown> | null | undefined,
): { ok: true; data: ParsedFortuneCreateBody } | { ok: false; error: FortuneCreateError } {
  const b = body ?? {};
  const question =
    (typeof b.question === "string" ? b.question : "") ||
    (typeof b.message === "string" ? b.message : "");
  const q = question.trim();

  if (q.length < 5) {
    return {
      ok: false,
      error: { code: "VALIDATION", message: "Fal sorusu çok kısa" },
    };
  }

  const nickname = (
    (typeof b.nickname === "string" ? b.nickname : "") ||
    (typeof b.displayName === "string" ? b.displayName : "") ||
    (typeof b.display_name === "string" ? b.display_name : "")
  ).trim();

  if (nickname.length < 2) {
    return {
      ok: false,
      error: { code: "VALIDATION", message: "Görünecek isim gerekli" },
    };
  }

  const rawTypeId =
    (typeof b.typeId === "string" ? b.typeId : "") ||
    (typeof b.fortuneType === "string" ? b.fortuneType : "") ||
    (typeof b.type === "string" ? b.type : "");

  const typeId = resolveFortuneTypeId(rawTypeId);
  if (!typeId) {
    return {
      ok: false,
      error: {
        code: "INVALID_TYPE",
        message: "Geçersiz fal türü",
      },
    };
  }

  const catalog = getFortuneType(typeId);
  if (!catalog) {
    return {
      ok: false,
      error: { code: "INVALID_TYPE", message: "Geçersiz fal türü" },
    };
  }

  let jetonAmount = catalog.jetonCost;
  const rawCost = Number(b.jetonCost ?? b.jetonAmount);
  if (Number.isFinite(rawCost) && rawCost > 0) {
    jetonAmount = Math.min(1000, Math.max(5, Math.round(rawCost)));
  } else if (!b.typeId && b.priority) {
    const priority = String(b.priority).toLowerCase();
    const costMap: Record<string, number> = {
      standard: 500,
      priority: 1000,
      urgent: 1500,
      vip: 2500,
      super: 2500,
    };
    jetonAmount = Math.min(1000, Math.max(20, costMap[priority] ?? catalog.jetonCost));
  }

  const isHidden = Boolean(b.isHidden);

  return {
    ok: true,
    data: { typeId, nickname, question: q, isHidden, jetonAmount },
  };
}

export type FortuneAction = "select" | "complete" | "refund";

export function parseFortuneAction(
  body: Record<string, unknown> | null | undefined,
): { action: FortuneAction; requestId: string } | null {
  const b = body ?? {};
  const action = String(b.action ?? "").trim().toLowerCase();
  const requestId = String(b.requestId ?? "").trim();
  if (!requestId) return null;
  if (action === "select" || action === "selected") {
    return { action: "select", requestId };
  }
  if (action === "complete" || action === "completed") {
    return { action: "complete", requestId };
  }
  if (action === "refund" || action === "refunded") {
    return { action: "refund", requestId };
  }
  return null;
}

/** Prisma / runtime hatalarını HTTP status'a map eder — beklenmeyen 500'i azaltır. */
export function mapFortuneCreateException(error: unknown): {
  status: number;
  code: string;
  message: string;
} {
  if (error && typeof error === "object" && "code" in error) {
    const prismaCode = String((error as { code: string }).code);
    switch (prismaCode) {
      case "P2002":
        return {
          status: 409,
          code: "CONFLICT",
          message: "Bu fal isteği zaten mevcut",
        };
      case "P2025":
        return {
          status: 404,
          code: "NOT_FOUND",
          message: "Kullanıcı bulunamadı",
        };
      case "P2003":
        return {
          status: 400,
          code: "INVALID_REFERENCE",
          message: "Geçersiz fal türü veya yayın referansı",
        };
      default:
        break;
    }
  }
  return {
    status: 500,
    code: "INTERNAL",
    message: "Failed to create fortune request",
  };
}
