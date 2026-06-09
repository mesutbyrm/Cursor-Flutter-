/**
 * GET /api/pk/history?battleType=voice_room&limit=20
 */
import { NextRequest } from "next/server";
import { optionalApiAuth } from "@/lib/verifyApiAuth";
import { listPkHistory } from "@/lib/pk/pkBattleService";
import { pkOk } from "@/lib/pk/pkRouteHelpers";

export async function GET(request: NextRequest) {
  const auth = await optionalApiAuth(request);
  const battleTypeParam = request.nextUrl.searchParams.get("battleType");
  const battleType =
    battleTypeParam === "voice_room" || battleTypeParam === "live_stream"
      ? battleTypeParam
      : undefined;
  const userId =
    request.nextUrl.searchParams.get("userId") ?? auth?.userId ?? undefined;
  const limit = Number(request.nextUrl.searchParams.get("limit") ?? 20);
  const items = await listPkHistory({ userId, battleType, limit });
  return pkOk({ items, history: items });
}
