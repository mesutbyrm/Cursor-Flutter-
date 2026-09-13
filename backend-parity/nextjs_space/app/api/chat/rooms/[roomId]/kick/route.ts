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
      action: body.action ?? 'kick',
      targetUserId: body.targetUserId ?? body.userId,
    })
    return callRoomRoute(
      forwarded,
      roomId,
      '@/app/api/chat/rooms/[roomId]/moderation/route',
      'POST',
    )
  } catch (e) {
    console.error('[chat/rooms/[roomId]/kick POST]', e)
    return NextResponse.json({ error: 'Kullanıcı atılamadı' }, { status: 500 })
  }
}
