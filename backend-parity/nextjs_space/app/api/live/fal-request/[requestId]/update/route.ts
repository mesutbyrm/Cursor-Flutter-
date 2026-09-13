import { NextRequest, NextResponse } from 'next/server'
import { resolveParams } from '@/lib/parity-route-params'
import { liveFalRequestUpdate } from '@/lib/parity-live-fal-handlers'

export const dynamic = 'force-dynamic'

type Ctx = { params: Promise<{ requestId: string }> | { requestId: string } }

export async function POST(req: NextRequest, context: Ctx) {
  try {
    const { requestId } = await resolveParams(context.params)
    return await liveFalRequestUpdate(req, requestId)
  } catch (e) {
    console.error('[live/fal-request/[requestId]/update POST]', e)
    return NextResponse.json({ error: 'Fal isteği güncellenemedi' }, { status: 500 })
  }
}
