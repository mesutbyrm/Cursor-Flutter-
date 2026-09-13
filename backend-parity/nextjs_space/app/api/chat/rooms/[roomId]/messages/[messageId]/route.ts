import { NextRequest, NextResponse } from 'next/server'
import { callRoomRoute } from '@/lib/chat-room-parity'
import { resolveParams } from '@/lib/parity-route-params'

export const dynamic = 'force-dynamic'

type RouteContext = {
  params: Promise<{ roomId: string; messageId: string }> | {
    roomId: string
    messageId: string
  }
}

export async function DELETE(req: NextRequest, context: RouteContext) {
  try {
    const { roomId, messageId } = await resolveParams(context.params)
    const url = new URL(req.url)
    url.searchParams.set('messageId', messageId)
    const forwarded = new NextRequest(url, { method: 'DELETE', headers: req.headers })
    return callRoomRoute(
      forwarded,
      roomId,
      '@/app/api/chat/rooms/[roomId]/messages/route',
      'DELETE',
    )
  } catch (e) {
    console.error('[chat/rooms/[roomId]/messages/[messageId] DELETE]', e)
    return NextResponse.json({ error: 'Mesaj silinemedi' }, { status: 500 })
  }
}
