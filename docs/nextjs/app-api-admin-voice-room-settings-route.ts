/**
 * canlifal.com — Admin Voice Room Settings
 * App Router: app/api/admin/voice-room-settings/route.ts
 */
import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { requireStaff } from "@/lib/auth/requireStaff";

export async function GET() {
  const staff = await requireStaff();
  if (!staff) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }
  const row =
    (await prisma.voiceRoomSettings.findUnique({ where: { id: "default" } })) ??
    (await prisma.voiceRoomSettings.create({ data: { id: "default" } }));
  return NextResponse.json({ success: true, data: row });
}

export async function POST(req: NextRequest) {
  const staff = await requireStaff();
  if (!staff) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }
  const body = await req.json();
  const row = await prisma.voiceRoomSettings.upsert({
    where: { id: "default" },
    create: { id: "default", ...body },
    update: body,
  });
  return NextResponse.json({ success: true, data: row });
}
