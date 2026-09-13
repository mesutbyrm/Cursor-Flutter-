import { NextRequest, NextResponse } from 'next/server'
import { callStreamRoute, streamIdFrom } from '@/lib/video-stream-parity'

export const dynamic = 'force-dynamic'

type Ctx = { params: Promise<{ streamId: string }> | { streamId: string } }

export async function GET(req: NextRequest, context: Ctx) {
  try {
    const streamId = await streamIdFrom(context)
    const res = await callStreamRoute(
      req,
      streamId,
      '@/app/api/video-streams/[streamId]/gifts/route',
      'GET',
    )
    if (res.ok) return res
    const url = new URL(req.url)
    url.pathname = '/api/gifts/insights/leaderboard'
    url.searchParams.set('streamId', streamId)
    const mod = await import('@/app/api/gifts/insights/leaderboard/route')
    return mod.GET(new NextRequest(url, { method: 'GET', headers: req.headers }))
  } catch (e) {
    console.error('[video-streams/[streamId]/gifts/leaderboard GET]', e)
    return NextResponse.json({ error: 'Hediye liderliği alınamadı' }, { status: 500 })
  }
}
