import { NextRequest, NextResponse } from 'next/server'
import { blogRecent } from '@/lib/parity-faz4-misc-handlers'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  try {
    return await blogRecent(req)
  } catch (e) {
    console.error('[blog/recent GET]', e)
    return NextResponse.json({ error: 'Son blog yazıları alınamadı' }, { status: 500 })
  }
}
