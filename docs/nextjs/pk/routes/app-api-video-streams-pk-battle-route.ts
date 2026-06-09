/**
 * GET/POST /api/video-streams/[streamId]/pk-battle
 */
import { NextRequest } from "next/server";
import { requireApiAuth, optionalApiAuth } from "@/lib/verifyApiAuth";
import { getActiveBattleForStream } from "@/lib/pk/pkBattleService";
import {
  handleLiveStreamPkAction,
  broadcastPkResult,
} from "@/lib/pk/pkBattleHandlers";
import { pkFail, pkOk } from "@/lib/pk/pkRouteHelpers";

type Ctx = { params: Promise<{ streamId: string }> };

export async function GET(_request: NextRequest, ctx: Ctx) {
  await optionalApiAuth(_request);
  const { streamId } = await ctx.params;
  const battle = await getActiveBattleForStream(streamId);
  return pkOk({ battle, pk: battle });
}

export async function POST(request: NextRequest, ctx: Ctx) {
  const auth = await requireApiAuth(request);
  if (!auth) return pkFail("Oturum açmanız gerekiyor", 401, "UNAUTHORIZED");

  const { streamId } = await ctx.params;
  let body: Record<string, unknown> = {};
  try {
    body = (await request.json()) as Record<string, unknown>;
  } catch {
    body = {};
  }

  const result = await handleLiveStreamPkAction(streamId, auth.userId, body);
  if (!result.ok) {
    return pkFail(result.error ?? "PK işlemi başarısız", 400);
  }

  const battle = result.battle as Record<string, unknown>;
  const events =
    "events" in result && Array.isArray(result.events)
      ? (result.events as string[])
      : ["pk:invite"];
  broadcastPkResult(battle, events);
  return pkOk({ battle, pk: battle });
}
