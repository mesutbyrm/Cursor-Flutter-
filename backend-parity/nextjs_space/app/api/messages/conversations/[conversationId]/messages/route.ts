import { NextRequest, NextResponse } from 'next/server'
import { GET as getThread, POST as postThread } from '@/app/api/messages/[userId]/route'
import { resolveParams } from '@/lib/parity-route-params'

export const dynamic = 'force-dynamic'

type RouteContext = {
  params: Promise<{ conversationId: string }> | { conversationId: string }
}

export async function GET(req: NextRequest, context: RouteContext) {
  try {
    const { conversationId } = await resolveParams(context.params)
    return getThread(req, { params: Promise.resolve({ userId: conversationId }) })
  } catch (e) {
    console.error('[messages/conversations/[id]/messages GET]', e)
    return NextResponse.json({ error: 'Mesajlar alınamadı' }, { status: 500 })
  }
}

export async function POST(req: NextRequest, context: RouteContext) {
  try {
    const { conversationId } = await resolveParams(context.params)
    return postThread(req, { params: Promise.resolve({ userId: conversationId }) })
  } catch (e) {
    console.error('[messages/conversations/[id]/messages POST]', e)
    return NextResponse.json({ error: 'Mesaj gönderilemedi' }, { status: 500 })
  }
}
