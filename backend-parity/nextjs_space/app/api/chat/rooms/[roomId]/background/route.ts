import { NextRequest, NextResponse } from 'next/server'
import { callRoomRoute, forwardJson, roomIdFrom } from '@/lib/chat-room-parity'

export const dynamic = 'force-dynamic'

type RouteContext = { params: Promise<{ roomId: string }> | { roomId: string } }

export async function GET(req: NextRequest, context: RouteContext) {
  try {
    const roomId = await roomIdFrom(context)
    const res = await callRoomRoute(
      req,
      roomId,
      '@/app/api/chat/rooms/[roomId]/settings/route',
      'GET',
    )
    const data = await res.json().catch(() => ({}))
    const backgroundImage =
      data.backgroundImage ?? data.bannerImage ?? data.data?.backgroundImage
    return NextResponse.json({
      success: true,
      backgroundImage,
      data: { backgroundImage },
    })
  } catch (e) {
    console.error('[chat/rooms/[roomId]/background GET]', e)
    return NextResponse.json({ error: 'Oda arka planı alınamadı' }, { status: 500 })
  }
}

export async function PATCH(req: NextRequest, context: RouteContext) {
  try {
    const roomId = await roomIdFrom(context)
    const body = await req.json().catch(() => ({}))
    const forwarded = await forwardJson(req, 'PATCH', {
      backgroundImage: body.backgroundImage ?? body.url ?? body.imageUrl,
      bannerImage: body.bannerImage,
    })
    return callRoomRoute(
      forwarded,
      roomId,
      '@/app/api/chat/rooms/[roomId]/settings/route',
      'PATCH',
    )
  } catch (e) {
    console.error('[chat/rooms/[roomId]/background PATCH]', e)
    return NextResponse.json({ error: 'Oda arka planı güncellenemedi' }, { status: 500 })
  }
}
