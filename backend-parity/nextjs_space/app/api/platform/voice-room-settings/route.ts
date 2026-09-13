import { NextResponse } from 'next/server'
import { getCachedPlatformSetting } from '@/lib/cache'

export const dynamic = 'force-dynamic'

const FALLBACK = {
  seatCount: 8,
  maxQueueLength: 50,
  musicRequestsEnabled: true,
  djModeEnabled: true,
}

export async function GET() {
  try {
    const settings = await getCachedPlatformSetting('voice_room_settings', FALLBACK)
    return NextResponse.json({
      success: true,
      data: settings,
      settings,
    })
  } catch (e) {
    console.error('[platform/voice-room-settings GET]', e)
    return NextResponse.json({ error: 'Sesli oda ayarları alınamadı' }, { status: 500 })
  }
}
