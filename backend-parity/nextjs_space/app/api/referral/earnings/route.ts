import { NextRequest, NextResponse } from 'next/server'
import { referralEarnings } from '@/lib/mobile-referral-handlers'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  try {
    return await referralEarnings(req)
  } catch (e) {
    console.error('[referral/earnings GET]', e)
    return NextResponse.json({ error: 'Referans kazançları alınamadı' }, { status: 500 })
  }
}
