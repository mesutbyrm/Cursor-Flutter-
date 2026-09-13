import { NextRequest, NextResponse } from 'next/server'
import { referralInviteLink } from '@/lib/mobile-referral-handlers'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  try {
    return await referralInviteLink(req)
  } catch (e) {
    console.error('[referral/invite-link GET]', e)
    return NextResponse.json({ error: 'Davet bağlantısı oluşturulamadı' }, { status: 500 })
  }
}
