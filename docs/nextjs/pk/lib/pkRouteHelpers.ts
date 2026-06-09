/**
 * Next.js PK route'ları için ortak yardımcılar.
 * pkBattleService.ts api mirror'dan kopyalandıktan sonra kullanın.
 */
import { NextResponse } from "next/server";

export function pkOk(data: Record<string, unknown>, status = 200) {
  return NextResponse.json({ success: true, ...data }, { status });
}

export function pkFail(
  message: string,
  status = 400,
  code = "BAD_REQUEST",
) {
  return NextResponse.json(
    { success: false, error: message, code },
    { status },
  );
}

export function unwrapBattle(body: Record<string, unknown> | null) {
  if (!body) return null;
  const b = body.battle ?? body.pk ?? body;
  return b && typeof b === "object" ? (b as Record<string, unknown>) : null;
}
