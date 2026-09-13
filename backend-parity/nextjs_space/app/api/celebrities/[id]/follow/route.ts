import { NextRequest, NextResponse } from 'next/server'
import { resolveParams } from '@/lib/parity-route-params'
import { celebrityFollow } from '@/lib/parity-celebrity-handlers'

export const dynamic = 'force-dynamic'

type RouteContext = { params: Promise<{ id: string }> | { id: string } }

export async function POST(req: NextRequest, context: RouteContext) {
  try {
    const { id } = await resolveParams(context.params)
    return await celebrityFollow(req, id)
  } catch (e) {
    console.error('[celebrities/[id]/follow POST]', e)
    return NextResponse.json({ error: 'Takip işlemi başarısız' }, { status: 500 })
  }
}

export async function DELETE(req: NextRequest, context: RouteContext) {
  try {
    const { id } = await resolveParams(context.params)
    return await celebrityFollow(req, id)
  } catch (e) {
    console.error('[celebrities/[id]/follow DELETE]', e)
    return NextResponse.json({ error: 'Takipten çıkılamadı' }, { status: 500 })
  }
}
