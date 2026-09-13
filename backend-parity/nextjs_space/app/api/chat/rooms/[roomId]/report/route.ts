import { NextRequest, NextResponse } from 'next/server'
import { callRoomRoute, forwardJson, roomIdFrom } from '@/lib/chat-room-parity'

export const dynamic = 'force-dynamic'

type RouteContext = { params: Promise<{ roomId: string }> | { roomId: string } }

export async function POST(req: NextRequest, context: RouteContext) {
  try {
    const roomId = await roomIdFrom(context)
    const body = await req.json().catch(() => ({}))
    const forwarded = await forwardJson(req, 'POST', {
      ...body,
      action: body.action ?? 'report',
      targetUserId: body.targetUserId ?? body.userId,
      reason: body.reason ?? body.message,
    })
    return callRoomRoute(
      forwarded,
      roomId,
      '@/app/api/chat/rooms/[roomId]/moderation/route',
      'POST',
    )
  } catch (e) {
    console.error('[chat/rooms/[roomId]/report POST]', e)
    return NextResponse.json({ error: 'Şikayet gönderilemedi' }, { status: 500 })
  }
}
