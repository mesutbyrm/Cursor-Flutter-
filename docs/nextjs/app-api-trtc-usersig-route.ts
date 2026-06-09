/**
 * canlifal.com Next.js — TRTC UserSig
 *
 * Hedef: app/api/trtc/usersig/route.ts
 *
 * Ortam:
 *   TRTC_SDK_APP_ID=1400000000
 *   TRTC_SECRET_KEY=...
 *
 * İstek:
 *   POST /api/trtc/usersig
 *   { "userId": "cuid_xxx", "roomId": "voice_room_cm..." }
 *   Authorization: Bearer <opsiyonel — yoksa body.userId kullanılır>
 *
 * Yanıt:
 *   { sdkAppId, userSig, userId, roomId }
 */

import { NextRequest, NextResponse } from "next/server";
import { optionalApiAuth } from "@/lib/verifyApiAuth";
import { generateTrtcUserSig } from "@/lib/trtcUserSig";

export async function POST(request: NextRequest) {
  let body: { userId?: string; roomId?: string } = {};
  try {
    body = (await request.json()) as typeof body;
  } catch {
    body = {};
  }

  const auth = await optionalApiAuth(request);
  const userId =
    body.userId?.trim() || auth?.userId || `guest-${Date.now()}`;
  const roomId = body.roomId?.trim() ?? "";

  try {
    const cred = generateTrtcUserSig(userId);
    return NextResponse.json({
      sdkAppId: cred.sdkAppId,
      userSig: cred.userSig,
      userId: cred.userId,
      roomId,
    });
  } catch (e) {
    const msg =
      e instanceof Error ? e.message : "UserSig oluşturulamadı";
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}
