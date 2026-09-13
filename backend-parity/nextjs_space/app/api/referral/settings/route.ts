import { NextRequest, NextResponse } from 'next/server'
import { referralSettings } from '@/lib/mobile-referral-handlers'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  try {
    return await referralSettings(req)
  } catch (e) {
    console.error('[referral/settings GET]', e)
    return NextResponse.json({ error: 'Referans ayarları alınamadı' }, { status: 500 })
  }
}
