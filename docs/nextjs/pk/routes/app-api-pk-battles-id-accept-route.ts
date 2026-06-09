/**
 * POST /api/pk/battles/[id]/accept
 */
import { NextRequest } from "next/server";
import { requireApiAuth } from "@/lib/verifyApiAuth";
import { acceptPkBattle } from "@/lib/pk/pkBattleService";
import { emitPkBattleEvent } from "@/lib/socket/giftHub";
import { pkFail, pkOk } from "@/lib/pk/pkRouteHelpers";

type Ctx = { params: Promise<{ id: string }> };

export async function POST(_request: NextRequest, ctx: Ctx) {
  const auth = await requireApiAuth(_request);
  if (!auth) return pkFail("Oturum açmanız gerekiyor", 401, "UNAUTHORIZED");

  const { id } = await ctx.params;
  const result = await acceptPkBattle(id, auth.userId);
  if (!result.ok) return pkFail(result.error ?? "Kabul edilemedi", 400);

  const battle = result.battle as Record<string, unknown>;
  for (const event of result.events ?? ["pk:accept", "pk:start"]) {
    emitPkBattleEvent(battle, event);
  }
  return pkOk({ battle, pk: battle });
}
