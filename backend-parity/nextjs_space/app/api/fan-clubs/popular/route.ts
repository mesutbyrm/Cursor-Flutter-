import { NextRequest, NextResponse } from 'next/server'
import { fanClubsPopular } from '@/lib/parity-fan-club-handlers'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  try {
    return await fanClubsPopular(req)
  } catch (e) {
    console.error('[fan-clubs/popular GET]', e)
    return NextResponse.json({ error: 'Fan kulüpleri alınamadı' }, { status: 500 })
  }
}
