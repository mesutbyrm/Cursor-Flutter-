import { NextRequest, NextResponse } from 'next/server'
import { siteAnimationsActive } from '@/lib/parity-faz4-misc-handlers'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  try {
    return await siteAnimationsActive(req)
  } catch (e) {
    console.error('[site-animations/active GET]', e)
    return NextResponse.json({ error: 'Animasyon kataloğu alınamadı' }, { status: 500 })
  }
}
