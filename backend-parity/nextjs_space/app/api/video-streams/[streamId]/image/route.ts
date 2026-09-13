import { NextRequest, NextResponse } from 'next/server'
import { callStreamRoute, streamIdFrom } from '@/lib/video-stream-parity'

export const dynamic = 'force-dynamic'

type Ctx = { params: Promise<{ streamId: string }> | { streamId: string } }

async function patchStream(req: NextRequest, context: Ctx) {
  const streamId = await streamIdFrom(context)
  const body = await req.json().catch(() => ({}))
  const forwarded = new NextRequest(req.url, {
    method: 'PATCH',
    headers: req.headers,
    body: JSON.stringify({
      broadcastImage:
        (body as { broadcastImage?: string }).broadcastImage ??
        (body as { imageUrl?: string }).imageUrl,
      isImageMode: (body as { isImageMode?: boolean }).isImageMode ?? true,
      ...body,
    }),
  })
  return callStreamRoute(
    forwarded,
    streamId,
    '@/app/api/video-streams/[streamId]/route',
    'PATCH',
  )
}

export async function POST(req: NextRequest, context: Ctx) {
  try {
    return await patchStream(req, context)
  } catch (e) {
    console.error('[video-streams/[streamId]/image POST]', e)
    return NextResponse.json({ error: 'Yayın görseli güncellenemedi' }, { status: 500 })
  }
}

export async function PATCH(req: NextRequest, context: Ctx) {
  try {
    return await patchStream(req, context)
  } catch (e) {
    console.error('[video-streams/[streamId]/image PATCH]', e)
    return NextResponse.json({ error: 'Yayın görseli güncellenemedi' }, { status: 500 })
  }
}
