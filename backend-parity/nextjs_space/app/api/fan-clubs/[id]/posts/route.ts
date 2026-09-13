import { NextRequest, NextResponse } from 'next/server'
import { resolveParams } from '@/lib/parity-route-params'
import { fanClubPosts } from '@/lib/parity-fan-club-handlers'

export const dynamic = 'force-dynamic'

type RouteContext = { params: Promise<{ id: string }> | { id: string } }

export async function GET(req: NextRequest, context: RouteContext) {
  try {
    const { id } = await resolveParams(context.params)
    return await fanClubPosts(req, id)
  } catch (e) {
    console.error('[fan-clubs/[id]/posts GET]', e)
    return NextResponse.json({ error: 'Gönderiler alınamadı' }, { status: 500 })
  }
}

export async function POST(req: NextRequest, context: RouteContext) {
  try {
    const { id } = await resolveParams(context.params)
    return await fanClubPosts(req, id)
  } catch (e) {
    console.error('[fan-clubs/[id]/posts POST]', e)
    return NextResponse.json({ error: 'Gönderi paylaşılamadı' }, { status: 500 })
  }
}
