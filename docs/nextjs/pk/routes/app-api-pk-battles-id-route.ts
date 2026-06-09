/**
 * GET /api/pk/battles/[id]
 * Hedef: app/api/pk/battles/[id]/route.ts
 */
import { NextRequest } from "next/server";
import { getBattleById } from "@/lib/pk/pkBattleService";
import { pkFail, pkOk } from "@/lib/pk/pkRouteHelpers";

type Ctx = { params: Promise<{ id: string }> };

export async function GET(_request: NextRequest, ctx: Ctx) {
  const { id } = await ctx.params;
  const battle = await getBattleById(id);
  if (!battle) return pkFail("PK bulunamadı", 404, "NOT_FOUND");
  return pkOk({ battle, pk: battle });
}
