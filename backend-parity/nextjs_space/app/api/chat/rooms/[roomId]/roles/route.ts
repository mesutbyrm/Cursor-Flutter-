import { NextRequest, NextResponse } from 'next/server'
import { callRoomRoute, forwardJson, roomIdFrom } from '@/lib/chat-room-parity'

export const dynamic = 'force-dynamic'

type RouteContext = { params: Promise<{ roomId: string }> | { roomId: string } }

export async function GET(req: NextRequest, context: RouteContext) {
  try {
    const roomId = await roomIdFrom(context)
    return callRoomRoute(
      req,
      roomId,
      '@/app/api/chat/rooms/[roomId]/moderation/route',
      'GET',
    )
  } catch (e) {
    console.error('[chat/rooms/[roomId]/roles GET]', e)
    return NextResponse.json({ error: 'Roller alınamadı' }, { status: 500 })
  }
}

export async function POST(req: NextRequest, context: RouteContext) {
  try {
    const roomId = await roomIdFrom(context)
    const body = await req.json().catch(() => ({}))
    const forwarded = await forwardJson(req, 'POST', {
      ...body,
      action: body.action ?? 'setRole',
      role: body.role,
      targetUserId: body.targetUserId ?? body.userId,
    })
    return callRoomRoute(
      forwarded,
      roomId,
      '@/app/api/chat/rooms/[roomId]/moderation/route',
      'POST',
    )
  } catch (e) {
    console.error('[chat/rooms/[roomId]/roles POST]', e)
    return NextResponse.json({ error: 'Rol güncellenemedi' }, { status: 500 })
  }
}
