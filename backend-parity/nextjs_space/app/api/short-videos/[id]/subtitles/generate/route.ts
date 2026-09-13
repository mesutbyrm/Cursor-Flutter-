import { NextRequest, NextResponse } from 'next/server'
import { resolveParams } from '@/lib/parity-route-params'
import { shortVideosSubtitlesGenerate } from '@/lib/parity-short-videos-handlers'

export const dynamic = 'force-dynamic'

type RouteContext = { params: Promise<{ id: string }> | { id: string } }

export async function POST(req: NextRequest, context: RouteContext) {
  try {
    const { id } = await resolveParams(context.params)
    return await shortVideosSubtitlesGenerate(req, id)
  } catch (e) {
    console.error('[short-videos/[id]/subtitles/generate POST]', e)
    return NextResponse.json({ error: 'Altyazı oluşturulamadı' }, { status: 500 })
  }
}
