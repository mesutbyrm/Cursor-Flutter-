import { NextRequest, NextResponse } from 'next/server'
import { tournamentsJoin } from '@/lib/parity-faz4-misc-handlers'

export const dynamic = 'force-dynamic'

export async function POST(req: NextRequest) {
  try {
    return await tournamentsJoin(req)
  } catch (e) {
    console.error('[tournaments/join POST]', e)
    return NextResponse.json({ error: 'Turnuvaya katılınamadı' }, { status: 500 })
  }
}
