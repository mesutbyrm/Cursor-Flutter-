/**
 * canlifal.com Next.js — FCM / OneSignal push token kaydı
 *
 * Hedef: app/api/devices/fcm/route.ts
 *
 * Prisma model (canlifal.com ile uyumlu):
 *   model DevicePushToken {
 *     id        String   @id @default(cuid())
 *     userId    String
 *     token     String   @unique
 *     platform  String   @default("unknown")
 *     createdAt DateTime @default(now())
 *     updatedAt DateTime @updatedAt
 *   }
 *
 * İstek:
 *   POST /api/devices/fcm
 *   Authorization: Bearer <mobil JWT>
 *   { "token": "...", "fcmToken": "...", "platform": "android", "provider": "onesignal" }
 */

import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { requireApiAuth } from "@/lib/verifyApiAuth";

export async function POST(request: NextRequest) {
  const auth = await requireApiAuth(request);
  if (!auth) {
    return NextResponse.json(
      { error: "Oturum açmanız gerekiyor" },
      { status: 401 },
    );
  }

  let body: {
    token?: string;
    fcmToken?: string;
    platform?: string;
    provider?: string;
  } = {};
  try {
    body = (await request.json()) as typeof body;
  } catch {
    return NextResponse.json({ error: "Geçersiz JSON" }, { status: 400 });
  }

  const token = (body.token ?? body.fcmToken ?? "").trim();
  if (token.length < 20) {
    return NextResponse.json({ error: "Geçersiz FCM token" }, { status: 400 });
  }

  const platformRaw = (body.platform ?? "unknown").trim() || "unknown";
  const provider = (body.provider ?? "").trim();
  const platform = provider ? `${provider}:${platformRaw}` : platformRaw;

  await prisma.devicePushToken.upsert({
    where: { token },
    create: { userId: auth.userId, token, platform },
    update: { userId: auth.userId, platform, updatedAt: new Date() },
  });

  return NextResponse.json({ success: true, registered: true });
}
