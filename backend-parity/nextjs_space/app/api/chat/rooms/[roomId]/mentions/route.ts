import { NextRequest, NextResponse } from 'next/server'
import { callRoomRoute, roomIdFrom } from '@/lib/chat-room-parity'

export const dynamic = 'force-dynamic'

type RouteContext = { params: Promise<{ roomId: string }> | { roomId: string } }

export async function GET(req: NextRequest, context: RouteContext) {
  try {
    const roomId = await roomIdFrom(context)
    const res = await callRoomRoute(
      req,
      roomId,
      '@/app/api/chat/rooms/[roomId]/messages/route',
      'GET',
    )
    const data = await res.json().catch(() => null)
    if (data && typeof data === 'object') {
      const mentions = (data as { mentions?: unknown }).mentions
      if (Array.isArray(mentions)) {
        return NextResponse.json({ success: true, mentions, items: mentions })
      }
    }
    return NextResponse.json({ success: true, mentions: [], items: [] })
  } catch (e) {
    console.error('[chat/rooms/[roomId]/mentions GET]', e)
    return NextResponse.json({ error: 'Bahsetmeler alınamadı' }, { status: 500 })
  }
}
