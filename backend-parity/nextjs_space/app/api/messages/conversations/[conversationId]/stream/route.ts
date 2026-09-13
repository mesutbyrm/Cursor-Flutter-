import { NextRequest } from 'next/server'
import { authenticateRequest } from '@/lib/mobile-auth'
import { resolveParams } from '@/lib/parity-route-params'

export const dynamic = 'force-dynamic'

type RouteContext = {
  params: Promise<{ conversationId: string }> | { conversationId: string }
}

export async function GET(req: NextRequest, context: RouteContext) {
  try {
    const user = await authenticateRequest(req)
    if (!user) {
      return new Response('Oturum gerekli', { status: 401 })
    }
    await resolveParams(context.params)

    const stream = new ReadableStream({
      start(controller) {
        const enc = new TextEncoder()
        const send = (line: string) => controller.enqueue(enc.encode(line))
        send(': connected\n\n')
        const interval = setInterval(() => {
          send(': ping\n\n')
        }, 25000)
        req.signal.addEventListener('abort', () => {
          clearInterval(interval)
          controller.close()
        })
      },
    })

    return new Response(stream, {
      headers: {
        'Content-Type': 'text/event-stream; charset=utf-8',
        'Cache-Control': 'no-cache, no-transform',
        Connection: 'keep-alive',
      },
    })
  } catch (e) {
    console.error('[messages/conversations/[id]/stream GET]', e)
    return new Response('Akış başlatılamadı', { status: 500 })
  }
}
