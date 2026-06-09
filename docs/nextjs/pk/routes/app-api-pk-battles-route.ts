/**
 * POST /api/pk/battles — PK daveti oluştur
 * Hedef: app/api/pk/battles/route.ts
 */
import { NextRequest } from "next/server";
import { requireApiAuth } from "@/lib/verifyApiAuth";
import { createPkInvite } from "@/lib/pk/pkBattleService";
import { emitPkBattleEvent } from "@/lib/socket/giftHub";
import { pkFail, pkOk } from "@/lib/pk/pkRouteHelpers";

export async function POST(request: NextRequest) {
  const auth = await requireApiAuth(request);
  if (!auth) return pkFail("Oturum açmanız gerekiyor", 401, "UNAUTHORIZED");

  let body: Record<string, unknown> = {};
  try {
    body = (await request.json()) as Record<string, unknown>;
  } catch {
    return pkFail("Geçersiz JSON", 400);
  }

  const battleType = body.battleType;
  if (battleType !== "voice_room" && battleType !== "live_stream") {
    return pkFail("Geçersiz PK isteği", 400, "VALIDATION_ERROR");
  }

  const result = await createPkInvite({
    battleType,
    challengerId: auth.userId,
    voiceRoomId: body.voiceRoomId?.toString(),
    opponentVoiceRoomId: body.opponentVoiceRoomId?.toString(),
    liveStreamId: body.liveStreamId?.toString(),
    opponentLiveStreamId: body.opponentLiveStreamId?.toString(),
    opponentId: body.opponentId?.toString(),
    durationSeconds: Number(body.durationSeconds ?? 300),
    targetScore: Number(body.targetScore ?? 150_000),
  });

  if (!result.ok) return pkFail(result.error ?? "PK oluşturulamadı", 400);

  const battle = result.battle as Record<string, unknown>;
  emitPkBattleEvent(battle, "pk:invite");
  return pkOk({ battle, pk: battle });
}
