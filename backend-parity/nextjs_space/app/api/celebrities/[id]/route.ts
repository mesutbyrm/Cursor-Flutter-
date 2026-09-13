import { NextRequest, NextResponse } from 'next/server'
import { resolveParams } from '@/lib/parity-route-params'
import { celebrityById } from '@/lib/parity-celebrity-handlers'

export const dynamic = 'force-dynamic'

type RouteContext = { params: Promise<{ id: string }> | { id: string } }

export async function GET(req: NextRequest, context: RouteContext) {
  try {
    const { id } = await resolveParams(context.params)
    return await celebrityById(req, id)
  } catch (e) {
    console.error('[celebrities/[id] GET]', e)
    return NextResponse.json({ error: 'Ünlü profili alınamadı' }, { status: 500 })
  }
}
