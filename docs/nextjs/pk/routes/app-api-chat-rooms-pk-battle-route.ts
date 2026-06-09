/**
 * GET/POST /api/chat/rooms/[roomId]/pk-battle
 * Flutter: PkBattleRemoteDataSource.inviteVoiceRoom / roomPkAction
 */
import { NextRequest } from "next/server";
import { requireApiAuth, optionalApiAuth } from "@/lib/verifyApiAuth";
import { getActiveBattleForRoom } from "@/lib/pk/pkBattleService";
import {
  handleVoiceRoomPkAction,
  broadcastPkResult,
} from "@/lib/pk/pkBattleHandlers";
import { pkFail, pkOk } from "@/lib/pk/pkRouteHelpers";

type Ctx = { params: Promise<{ roomId: string }> };

export async function GET(_request: NextRequest, ctx: Ctx) {
  await optionalApiAuth(_request);
  const { roomId } = await ctx.params;
  const battle = await getActiveBattleForRoom(roomId);
  return pkOk({ battle, pk: battle });
}

export async function POST(request: NextRequest, ctx: Ctx) {
  const auth = await requireApiAuth(request);
  if (!auth) return pkFail("Oturum açmanız gerekiyor", 401, "UNAUTHORIZED");

  const { roomId } = await ctx.params;
  let body: Record<string, unknown> = {};
  try {
    body = (await request.json()) as Record<string, unknown>;
  } catch {
    body = {};
  }

  const result = await handleVoiceRoomPkAction(roomId, auth.userId, body);
  if (!result.ok) {
    return pkFail(result.error ?? "PK işlemi başarısız", 400);
  }

  const battle = result.battle as Record<string, unknown>;
  const events =
    "events" in result && Array.isArray(result.events)
      ? (result.events as string[])
      : "event" in result && result.event
        ? [String(result.event)]
        : ["pk:invite"];
  broadcastPkResult(battle, events);
  return pkOk({ battle, pk: battle });
}
