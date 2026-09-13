import { NextRequest, NextResponse } from 'next/server'
import { callRoomRoute, forwardJson, roomIdFrom } from '@/lib/chat-room-parity'
import { resolveParams } from '@/lib/parity-route-params'

export const dynamic = 'force-dynamic'

type RouteContext = {
  params: Promise<{ roomId: string; songId: string }> | {
    roomId: string
    songId: string
  }
}

export async function GET(req: NextRequest, context: RouteContext) {
  try {
    const roomId = await roomIdFrom(context)
    return callRoomRoute(
      req,
      roomId,
      '@/app/api/chat/rooms/[roomId]/music/route',
      'GET',
    )
  } catch (e) {
    console.error('[chat/rooms/[roomId]/song/[songId] GET]', e)
    return NextResponse.json({ error: 'Şarkı bilgisi alınamadı' }, { status: 500 })
  }
}

export async function DELETE(req: NextRequest, context: RouteContext) {
  try {
    const roomId = await roomIdFrom(context)
    const { songId } = await resolveParams(context.params)
    const body = await req.json().catch(() => ({}))
    const forwarded = await forwardJson(req, 'DELETE', {
      ...body,
      videoId: songId,
    })
    return callRoomRoute(
      forwarded,
      roomId,
      '@/app/api/chat/rooms/[roomId]/music/route',
      'DELETE',
    )
  } catch (e) {
    console.error('[chat/rooms/[roomId]/song/[songId] DELETE]', e)
    return NextResponse.json({ error: 'Şarkı kaldırılamadı' }, { status: 500 })
  }
}
