import { NextRequest, NextResponse } from 'next/server'
import { referralStats } from '@/lib/mobile-referral-handlers'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  try {
    return await referralStats(req)
  } catch (e) {
    console.error('[referral/stats GET]', e)
    return NextResponse.json({ error: 'Referans istatistikleri alınamadı' }, { status: 500 })
  }
}
