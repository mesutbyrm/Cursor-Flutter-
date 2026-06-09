/**
 * canlifal.com Next.js — sesli oda arka plan kataloğu
 *
 * Hedef: app/api/chat/rooms/backgrounds/route.ts
 *
 * Web istemcisi statik /images/voice-bg-*.jpg kullanır; Flutter bu API'yi çağırır.
 *
 * İstek:
 *   GET /api/chat/rooms/backgrounds
 *   Auth: gerekmez (public katalog)
 *
 * Yanıt:
 *   { "backgrounds": ["https://canlifal.com/images/voice-bg-1.jpg", ...] }
 *   veya { "backgrounds": [{ "id", "url", "label" }, ...] }
 */

import { NextResponse } from "next/server";
import { listVoiceRoomBackgrounds } from "@/lib/voiceRoomBackgrounds";

export async function GET() {
  const backgrounds = listVoiceRoomBackgrounds();
  return NextResponse.json({ backgrounds });
}
