/**
 * POST /api/pk/battles/[id]/reject
 */
import { NextRequest } from "next/server";
import { requireApiAuth } from "@/lib/verifyApiAuth";
import { rejectPkBattle } from "@/lib/pk/pkBattleService";
import { emitPkBattleEvent } from "@/lib/socket/giftHub";
import { pkFail, pkOk } from "@/lib/pk/pkRouteHelpers";

type Ctx = { params: Promise<{ id: string }> };

export async function POST(_request: NextRequest, ctx: Ctx) {
  const auth = await requireApiAuth(_request);
  if (!auth) return pkFail("Oturum açmanız gerekiyor", 401, "UNAUTHORIZED");

  const { id } = await ctx.params;
  const result = await rejectPkBattle(id, auth.userId);
  if (!result.ok) return pkFail(result.error ?? "Reddedilemedi", 400);

  const battle = result.battle as Record<string, unknown>;
  emitPkBattleEvent(battle, result.event ?? "pk:reject");
  return pkOk({ battle, pk: battle });
}
