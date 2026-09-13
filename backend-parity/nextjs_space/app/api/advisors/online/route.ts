import { NextRequest, NextResponse } from 'next/server'
import { advisorsOnline } from '@/lib/parity-faz4-misc-handlers'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  try {
    return await advisorsOnline(req)
  } catch (e) {
    console.error('[advisors/online GET]', e)
    return NextResponse.json({ error: 'Çevrimiçi falcılar alınamadı' }, { status: 500 })
  }
}
