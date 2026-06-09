/**
 * POST /api/pk/battles/[id]/end
 */
import { NextRequest } from "next/server";
import { requireApiAuth } from "@/lib/verifyApiAuth";
import { endPkBattle, getBattleById } from "@/lib/pk/pkBattleService";
import { emitPkBattleEvent } from "@/lib/socket/giftHub";
import { pkFail, pkOk } from "@/lib/pk/pkRouteHelpers";

type Ctx = { params: Promise<{ id: string }> };

export async function POST(_request: NextRequest, ctx: Ctx) {
  const auth = await requireApiAuth(_request);
  if (!auth) return pkFail("Oturum açmanız gerekiyor", 401, "UNAUTHORIZED");

  const { id } = await ctx.params;
  const battle = await getBattleById(id);
  if (!battle) return pkFail("PK bulunamadı", 404, "NOT_FOUND");
  if (
    battle.challengerId !== auth.userId &&
    battle.opponentId !== auth.userId
  ) {
    return pkFail("Yetki yok", 403, "FORBIDDEN");
  }

  const result = await endPkBattle(id, "manual");
  if (!result.ok) return pkFail(result.error ?? "Bitirilemedi", 400);

  const payload = result.battle as Record<string, unknown>;
  for (const event of result.events ?? ["pk:end", "pk:winner"]) {
    emitPkBattleEvent(payload, event);
  }
  return pkOk({ battle: payload, pk: payload });
}
