import { NextRequest, NextResponse } from 'next/server'
import { resolveParams } from '@/lib/parity-route-params'
import { celebrityPosts } from '@/lib/parity-celebrity-handlers'

export const dynamic = 'force-dynamic'

type RouteContext = { params: Promise<{ id: string }> | { id: string } }

export async function GET(req: NextRequest, context: RouteContext) {
  try {
    const { id } = await resolveParams(context.params)
    return await celebrityPosts(req, id)
  } catch (e) {
    console.error('[celebrities/[id]/posts GET]', e)
    return NextResponse.json({ error: 'Gönderiler alınamadı' }, { status: 500 })
  }
}
