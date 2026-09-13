import { NextRequest, NextResponse } from 'next/server'
import { giftsDisplaySettings } from '@/lib/parity-faz4-misc-handlers'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  try {
    return await giftsDisplaySettings(req)
  } catch (e) {
    console.error('[gifts/display-settings GET]', e)
    return NextResponse.json({ error: 'Hediye görünüm ayarları alınamadı' }, { status: 500 })
  }
}
