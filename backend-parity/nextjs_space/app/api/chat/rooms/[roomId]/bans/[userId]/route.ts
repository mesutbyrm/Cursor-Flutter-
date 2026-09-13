import { NextRequest, NextResponse } from 'next/server'
import { callRoomRoute, forwardJson } from '@/lib/chat-room-parity'
import { resolveParams } from '@/lib/parity-route-params'

export const dynamic = 'force-dynamic'

type RouteContext = {
  params: Promise<{ roomId: string; userId: string }> | {
    roomId: string
    userId: string
  }
}

export async function POST(req: NextRequest, context: RouteContext) {
  try {
    const { roomId, userId } = await resolveParams(context.params)
    const body = await req.json().catch(() => ({}))
    const forwarded = await forwardJson(req, 'POST', {
      ...body,
      action: body.action ?? 'ban',
      targetUserId: userId,
    })
    return callRoomRoute(
      forwarded,
      roomId,
      '@/app/api/chat/rooms/[roomId]/moderation/route',
      'POST',
    )
  } catch (e) {
    console.error('[chat/rooms/[roomId]/bans/[userId] POST]', e)
    return NextResponse.json({ error: 'Ban işlemi başarısız' }, { status: 500 })
  }
}

export async function DELETE(req: NextRequest, context: RouteContext) {
  try {
    const { roomId, userId } = await resolveParams(context.params)
    const forwarded = await forwardJson(req, 'POST', {
      action: 'unban',
      targetUserId: userId,
    })
    return callRoomRoute(
      forwarded,
      roomId,
      '@/app/api/chat/rooms/[roomId]/moderation/route',
      'POST',
    )
  } catch (e) {
    console.error('[chat/rooms/[roomId]/bans/[userId] DELETE]', e)
    return NextResponse.json({ error: 'Ban kaldırılamadı' }, { status: 500 })
  }
}
