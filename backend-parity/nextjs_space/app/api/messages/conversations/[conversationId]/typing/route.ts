import { NextRequest, NextResponse } from 'next/server'
import { authenticateRequest } from '@/lib/mobile-auth'
import { isPeerTyping, setDmTyping } from '@/lib/dm-typing-state'
import { resolveParams } from '@/lib/parity-route-params'

export const dynamic = 'force-dynamic'

type RouteContext = {
  params: Promise<{ conversationId: string }> | { conversationId: string }
}

export async function GET(req: NextRequest, context: RouteContext) {
  try {
    const user = await authenticateRequest(req)
    if (!user) {
      return NextResponse.json({ error: 'Oturum gerekli' }, { status: 401 })
    }
    const { conversationId } = await resolveParams(context.params)
    const peerTyping = isPeerTyping(conversationId, user.id)
    return NextResponse.json({ peerTyping, typing: peerTyping })
  } catch (e) {
    console.error('[messages/conversations/[id]/typing GET]', e)
    return NextResponse.json({ error: 'Yazma durumu okunamadı' }, { status: 500 })
  }
}

export async function POST(req: NextRequest, context: RouteContext) {
  try {
    const user = await authenticateRequest(req)
    if (!user) {
      return NextResponse.json({ error: 'Oturum gerekli' }, { status: 401 })
    }
    const { conversationId } = await resolveParams(context.params)
    const body = await req.json().catch(() => ({}))
    const typing = body.typing !== false && body.isTyping !== false
    setDmTyping(conversationId, user.id, typing)
    const peerTyping = isPeerTyping(conversationId, user.id)
    return NextResponse.json({ peerTyping, ok: true })
  } catch (e) {
    console.error('[messages/conversations/[id]/typing POST]', e)
    return NextResponse.json({ error: 'Yazma durumu güncellenemedi' }, { status: 500 })
  }
}
