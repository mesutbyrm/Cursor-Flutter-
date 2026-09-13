import { NextRequest, NextResponse } from 'next/server'
import { shortVideosViewedMe } from '@/lib/parity-short-videos-handlers'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  try {
    return await shortVideosViewedMe(req)
  } catch (e) {
    console.error('[short-videos/viewed/me GET]', e)
    return NextResponse.json({ error: 'İzleme geçmişi alınamadı' }, { status: 500 })
  }
}
