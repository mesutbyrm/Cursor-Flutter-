import { NextRequest, NextResponse } from 'next/server'
import { referralMe } from '@/lib/mobile-referral-handlers'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  try {
    return await referralMe(req)
  } catch (e) {
    console.error('[referral/me GET]', e)
    return NextResponse.json({ error: 'Referans bilgisi alınamadı' }, { status: 500 })
  }
}
