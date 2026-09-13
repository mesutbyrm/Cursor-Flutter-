import { NextRequest, NextResponse } from 'next/server'
import { liveFalRequestCreate } from '@/lib/parity-live-fal-handlers'

export const dynamic = 'force-dynamic'

export async function POST(req: NextRequest) {
  try {
    return await liveFalRequestCreate(req)
  } catch (e) {
    console.error('[live/fal-request/create POST]', e)
    return NextResponse.json({ error: 'Fal isteği oluşturulamadı' }, { status: 500 })
  }
}
