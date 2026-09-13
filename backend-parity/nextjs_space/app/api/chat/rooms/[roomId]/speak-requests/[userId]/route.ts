import { NextRequest, NextResponse } from 'next/server'
import { callRoomRoute, roomIdFrom } from '@/lib/chat-room-parity'
import { resolveParams } from '@/lib/parity-route-params'

export const dynamic = 'force-dynamic'

type RouteContext = {
  params: Promise<{ roomId: string; userId: string }> | {
    roomId: string
    userId: string
  }
}

export async function DELETE(req: NextRequest, context: RouteContext) {
  try {
    const roomId = await roomIdFrom(context)
    const { userId } = await resolveParams(context.params)
    return callRoomRoute(
      req,
      roomId,
      '@/app/api/chat/rooms/[roomId]/speak-requests/[targetUserId]/reject/route',
      'DELETE',
      { targetUserId: userId },
    )
  } catch (e) {
    console.error('[chat/rooms/[roomId]/speak-requests/[userId] DELETE]', e)
    return NextResponse.json({ error: 'Konuşma isteği reddedilemedi' }, { status: 500 })
  }
}

export async function POST(req: NextRequest, context: RouteContext) {
  try {
    const roomId = await roomIdFrom(context)
    const { userId } = await resolveParams(context.params)
    const body = await req.json().catch(() => ({}))
    const action = body.action ?? 'approve'
    const sub =
      action === 'approve'
        ? 'approve'
        : action === 'block'
          ? 'block'
          : 'reject'
    const mod = await import(
      `@/app/api/chat/rooms/[roomId]/speak-requests/[targetUserId]/${sub}/route`
    )
    const handler = mod.POST ?? mod.DELETE
    return handler(req, {
      params: Promise.resolve({ roomId, targetUserId: userId }),
    })
  } catch (e) {
    console.error('[chat/rooms/[roomId]/speak-requests/[userId] POST]', e)
    return NextResponse.json({ error: 'Konuşma isteği işlenemedi' }, { status: 500 })
  }
}
