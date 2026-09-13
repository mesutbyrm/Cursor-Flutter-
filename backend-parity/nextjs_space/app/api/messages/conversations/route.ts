import { NextRequest, NextResponse } from 'next/server'
import { GET as listMessages } from '@/app/api/messages/route'
import { POST as postMessageRequest } from '@/app/api/messages/request/route'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  try {
    return listMessages(req)
  } catch (e) {
    console.error('[messages/conversations GET]', e)
    return NextResponse.json({ error: 'Sohbet listesi alınamadı' }, { status: 500 })
  }
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json().catch(() => ({}))
    const recipientId =
      body.recipientId ?? body.receiverId ?? body.userId ?? body.peerId
    const forwarded = new NextRequest(req.url, {
      method: 'POST',
      headers: req.headers,
      body: JSON.stringify({
        ...body,
        receiverId: recipientId,
        action: body.action ?? 'start',
      }),
    })
    return postMessageRequest(forwarded)
  } catch (e) {
    console.error('[messages/conversations POST]', e)
    return NextResponse.json({ error: 'Sohbet başlatılamadı' }, { status: 500 })
  }
}
