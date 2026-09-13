import { NextRequest, NextResponse } from 'next/server'
import { callRoomRoute, forwardJson, roomIdFrom } from '@/lib/chat-room-parity'

export const dynamic = 'force-dynamic'

type RouteContext = { params: Promise<{ roomId: string }> | { roomId: string } }

async function toSeats(req: NextRequest, context: RouteContext, method: 'PATCH' | 'POST') {
  const roomId = await roomIdFrom(context)
  const body = await req.json().catch(() => ({}))
  const action = body.action ?? 'take'
  const forwarded = await forwardJson(req, 'PATCH', {
    ...body,
    action,
    targetUserId: body.targetUserId ?? body.userId,
  })
  if (method === 'PATCH') {
    return callRoomRoute(
      forwarded,
      roomId,
      '@/app/api/chat/rooms/[roomId]/seats/route',
      'PATCH',
    )
  }
  return callRoomRoute(
    forwarded,
    roomId,
    '@/app/api/chat/rooms/[roomId]/seats/route',
    'PATCH',
  )
}

export async function POST(req: NextRequest, context: RouteContext) {
  try {
    return await toSeats(req, context, 'POST')
  } catch (e) {
    console.error('[chat/rooms/[roomId]/join-seat POST]', e)
    return NextResponse.json({ error: 'Koltuğa oturulamadı' }, { status: 500 })
  }
}

export async function PATCH(req: NextRequest, context: RouteContext) {
  try {
    return await toSeats(req, context, 'PATCH')
  } catch (e) {
    console.error('[chat/rooms/[roomId]/join-seat PATCH]', e)
    return NextResponse.json({ error: 'Koltuk güncellenemedi' }, { status: 500 })
  }
}
