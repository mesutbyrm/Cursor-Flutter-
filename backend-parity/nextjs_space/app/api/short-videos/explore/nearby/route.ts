import { NextRequest, NextResponse } from 'next/server'
import { callShortVideosExplore } from '@/lib/parity-short-videos-handlers'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  try {
    const url = new URL(req.url)
    const lat = url.searchParams.get('lat') ?? url.searchParams.get('latitude')
    const lng = url.searchParams.get('lng') ?? url.searchParams.get('longitude')
    if (lat) url.searchParams.set('lat', lat)
    if (lng) url.searchParams.set('lng', lng)
    url.searchParams.set('nearby', '1')
    const proxied = new NextRequest(url, { method: 'GET', headers: req.headers })
    return callShortVideosExplore(proxied, '/api/short-videos/explore')
  } catch (e) {
    console.error('[short-videos/explore/nearby GET]', e)
    return NextResponse.json({ error: 'Yakındaki videolar alınamadı' }, { status: 500 })
  }
}
