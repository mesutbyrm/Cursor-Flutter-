import { NextRequest, NextResponse } from 'next/server'

export async function adminPaymentsStream(req: NextRequest) {
  const encoder = new TextEncoder()
  const stream = new ReadableStream({
    start(controller) {
      controller.enqueue(
        encoder.encode(`data: ${JSON.stringify({ type: 'connected' })}\n\n`),
      )
      const ping = setInterval(() => {
        try {
          controller.enqueue(
            encoder.encode(`data: ${JSON.stringify({ type: 'ping' })}\n\n`),
          )
        } catch {
          clearInterval(ping)
        }
      }, 30000)
      req.signal.addEventListener('abort', () => {
        clearInterval(ping)
        controller.close()
      })
    },
  })
  return new Response(stream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache, no-transform',
      Connection: 'keep-alive',
    },
  })
}

export async function adminPaymentDismissPending(req: NextRequest) {
  const body = await req.json().catch(() => ({}))
  const forwarded = new NextRequest(req.url, {
    method: 'PATCH',
    headers: req.headers,
    body: JSON.stringify({ action: 'dismiss', ...body }),
  })
  const mod = await import('@/app/api/admin/cfc-payment-requests/route')
  if (typeof mod.PATCH === 'function') {
    return mod.PATCH(forwarded)
  }
  return NextResponse.json({ success: true, dismissed: true })
}

export async function adminUserSubresourceEmpty(_req: NextRequest, key: string) {
  return NextResponse.json({ success: true, [key]: [], items: [], data: [] })
}
