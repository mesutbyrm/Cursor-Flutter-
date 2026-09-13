import { NextRequest, NextResponse } from 'next/server'
import { tellerReviews } from '@/lib/parity-faz4-misc-handlers'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  try {
    return await tellerReviews(req)
  } catch (e) {
    console.error('[teller/reviews GET]', e)
    return NextResponse.json({ error: 'Yorumlar alınamadı' }, { status: 500 })
  }
}
