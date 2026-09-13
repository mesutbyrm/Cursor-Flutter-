import { NextRequest, NextResponse } from 'next/server'
import { resolveParams } from '@/lib/parity-route-params'
import { fanClubJoin } from '@/lib/parity-fan-club-handlers'

export const dynamic = 'force-dynamic'

type RouteContext = { params: Promise<{ id: string }> | { id: string } }

export async function POST(req: NextRequest, context: RouteContext) {
  try {
    const { id } = await resolveParams(context.params)
    return await fanClubJoin(req, id)
  } catch (e) {
    console.error('[fan-clubs/[id]/join POST]', e)
    return NextResponse.json({ error: 'Fan kulübüne katılınamadı' }, { status: 500 })
  }
}
