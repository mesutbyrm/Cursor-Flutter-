import { NextRequest, NextResponse } from 'next/server'
import { referralLedger } from '@/lib/mobile-referral-handlers'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  try {
    return await referralLedger(req)
  } catch (e) {
    console.error('[referral/ledger GET]', e)
    return NextResponse.json({ error: 'Referans defteri alınamadı' }, { status: 500 })
  }
}
