import { NextRequest, NextResponse } from 'next/server'
import { callRoomRoute, roomIdFrom } from '@/lib/chat-room-parity'
import { forwardJson } from '@/lib/chat-room-parity'

export const dynamic = 'force-dynamic'

type RouteContext = { params: Promise<{ roomId: string }> | { roomId: string } }

export async function GET(req: NextRequest, context: RouteContext) {
  try {
    const roomId = await roomIdFrom(context)
    return callRoomRoute(
      req,
      roomId,
      '@/app/api/chat/rooms/[roomId]/music-queue/route',
      'GET',
    )
  } catch (e) {
    console.error('[chat/rooms/[roomId]/queue GET]', e)
    return NextResponse.json({ error: 'Müzik kuyruğu alınamadı' }, { status: 500 })
  }
}

export async function POST(req: NextRequest, context: RouteContext) {
  try {
    const roomId = await roomIdFrom(context)
    const body = await req.json().catch(() => ({}))
    const forwarded = await forwardJson(req, 'POST', body)
    return callRoomRoute(
      forwarded,
      roomId,
      '@/app/api/chat/rooms/[roomId]/song-request/route',
      'POST',
    )
  } catch (e) {
    console.error('[chat/rooms/[roomId]/queue POST]', e)
    return NextResponse.json({ error: 'Kuyruğa eklenemedi' }, { status: 500 })
  }
}
