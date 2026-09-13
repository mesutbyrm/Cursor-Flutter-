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
    const bannedWords = data.bannedWords ?? data.data?.bannedWords ?? []
    return NextResponse.json({
      success: true,
      bannedWords,
      data: { bannedWords },
    })
  } catch (e) {
    console.error('[chat/rooms/[roomId]/banned-words GET]', e)
    return NextResponse.json({ error: 'Yasaklı kelimeler alınamadı' }, { status: 500 })
  }
}

export async function PATCH(req: NextRequest, context: RouteContext) {
  try {
    const roomId = await roomIdFrom(context)
    const body = await req.json().catch(() => ({}))
    const forwarded = await forwardJson(req, 'PATCH', {
      bannedWords: body.bannedWords ?? body.words ?? body.list,
    })
    return callRoomRoute(
      forwarded,
      roomId,
      '@/app/api/chat/rooms/[roomId]/settings/route',
      'PATCH',
    )
  } catch (e) {
    console.error('[chat/rooms/[roomId]/banned-words PATCH]', e)
    return NextResponse.json({ error: 'Yasaklı kelimeler güncellenemedi' }, { status: 500 })
  }
}
