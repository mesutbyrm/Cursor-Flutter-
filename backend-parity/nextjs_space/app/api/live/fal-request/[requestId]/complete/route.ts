import { NextRequest, NextResponse } from 'next/server'
import { resolveParams } from '@/lib/parity-route-params'
import { liveFalRequestComplete } from '@/lib/parity-live-fal-handlers'

export const dynamic = 'force-dynamic'

type Ctx = { params: Promise<{ requestId: string }> | { requestId: string } }

export async function POST(req: NextRequest, context: Ctx) {
  try {
    const { requestId } = await resolveParams(context.params)
    return await liveFalRequestComplete(req, requestId)
  } catch (e) {
    console.error('[live/fal-request/[requestId]/complete POST]', e)
    return NextResponse.json({ error: 'Fal isteği tamamlanamadı' }, { status: 500 })
  }
}
