import { NextRequest, NextResponse } from 'next/server'
import { callRoomRoute, forwardJson, roomIdFrom } from '@/lib/chat-room-parity'

export const dynamic = 'force-dynamic'

type RouteContext = { params: Promise<{ roomId: string }> | { roomId: string } }

export async function GET(req: NextRequest, context: RouteContext) {
  try {
    const { GET: youtubeAudio } = await import('@/app/api/chat/youtube-audio/route')
    return youtubeAudio(req)
  } catch (e) {
    console.error('[chat/rooms/[roomId]/music-request-by-query GET]', e)
    return NextResponse.json({ error: 'Müzik araması başarısız' }, { status: 500 })
  }
}

export async function POST(req: NextRequest, context: RouteContext) {
  try {
    const roomId = await roomIdFrom(context)
    const body = await req.json().catch(() => ({}))
    const query = body.query ?? body.q ?? body.title
    const forwarded = await forwardJson(req, 'POST', {
      ...body,
      query,
      videoId: body.videoId,
      title: body.title ?? query,
    })
    return callRoomRoute(
      forwarded,
      roomId,
      '@/app/api/chat/rooms/[roomId]/song-request/route',
      'POST',
    )
  } catch (e) {
    console.error('[chat/rooms/[roomId]/music-request-by-query POST]', e)
    return NextResponse.json({ error: 'Müzik isteği gönderilemedi' }, { status: 500 })
  }
}
