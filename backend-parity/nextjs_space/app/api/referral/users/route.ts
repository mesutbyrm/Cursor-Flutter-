import { NextRequest, NextResponse } from 'next/server'
import { referralUsers } from '@/lib/mobile-referral-handlers'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  try {
    return await referralUsers(req)
  } catch (e) {
    console.error('[referral/users GET]', e)
    return NextResponse.json({ error: 'Davet edilen kullanıcılar alınamadı' }, { status: 500 })
  }
}
