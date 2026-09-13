import { NextRequest, NextResponse } from 'next/server'
import { liveFalRequestsList } from '@/lib/parity-live-fal-handlers'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  try {
    return await liveFalRequestsList(req)
  } catch (e) {
    console.error('[live/fal-requests GET]', e)
    return NextResponse.json({ error: 'Fal istekleri alınamadı' }, { status: 500 })
  }
}
