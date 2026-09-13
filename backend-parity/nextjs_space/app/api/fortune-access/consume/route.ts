import { NextRequest, NextResponse } from 'next/server'
import { fortuneAccessConsume } from '@/lib/parity-faz4-misc-handlers'

export const dynamic = 'force-dynamic'

export async function POST(req: NextRequest) {
  try {
    return await fortuneAccessConsume(req)
  } catch (e) {
    console.error('[fortune-access/consume POST]', e)
    return NextResponse.json({ error: 'Fal hakkı kullanılamadı' }, { status: 500 })
  }
}
