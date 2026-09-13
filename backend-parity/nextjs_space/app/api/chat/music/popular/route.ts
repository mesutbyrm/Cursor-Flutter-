import { NextRequest, NextResponse } from 'next/server'
import { getCachedPlatformSetting } from '@/lib/cache'

export const dynamic = 'force-dynamic'

const DEFAULT_ITEMS = [
  { title: 'Yalan', artist: 'Tarkan', query: 'Tarkan Yalan', videoId: 'nboC0smLRsE' },
]

export async function GET(req: NextRequest) {
  try {
    const cached = await getCachedPlatformSetting('chat_music_popular', DEFAULT_ITEMS)
    const items = Array.isArray(cached) ? cached : DEFAULT_ITEMS

    try {
      const { GET: youtubeAudio } = await import('@/app/api/chat/youtube-audio/route')
      const proxied = await youtubeAudio(req)
      if (proxied.ok) {
        const data = await proxied.json().catch(() => null)
        const list = data?.items ?? data?.results ?? data?.data
        if (Array.isArray(list) && list.length > 0) {
          return NextResponse.json({ items: list, success: true })
        }
      }
    } catch {
      // youtube-audio yoksa cache / varsayılan
    }

    return NextResponse.json({ items, success: true })
  } catch (e) {
    console.error('[chat/music/popular GET]', e)
    return NextResponse.json({ error: 'Popüler müzik listesi alınamadı' }, { status: 500 })
  }
}
