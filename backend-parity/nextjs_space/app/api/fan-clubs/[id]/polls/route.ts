import { NextRequest, NextResponse } from 'next/server'
import { resolveParams } from '@/lib/parity-route-params'
import { fanClubPolls } from '@/lib/parity-fan-club-handlers'

export const dynamic = 'force-dynamic'

type RouteContext = { params: Promise<{ id: string }> | { id: string } }

export async function GET(req: NextRequest, context: RouteContext) {
  try {
    const { id } = await resolveParams(context.params)
    return await fanClubPolls(req, id)
  } catch (e) {
    console.error('[fan-clubs/[id]/polls GET]', e)
    return NextResponse.json({ error: 'Anketler alınamadı' }, { status: 500 })
  }
}

export async function POST(req: NextRequest, context: RouteContext) {
  try {
    const { id } = await resolveParams(context.params)
    return await fanClubPolls(req, id)
  } catch (e) {
    console.error('[fan-clubs/[id]/polls POST]', e)
    return NextResponse.json({ error: 'Anket oluşturulamadı' }, { status: 500 })
  }
}
