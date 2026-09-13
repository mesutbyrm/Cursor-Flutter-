import { NextRequest, NextResponse } from 'next/server'
import { adminUserSubresourceEmpty } from '@/lib/parity-admin-handlers'

export const dynamic = 'force-dynamic'

export async function GET(_req: NextRequest) {
  try {
    return await adminUserSubresourceEmpty(_req, 'ads')
  } catch (e) {
    console.error('[admin/users/[userId]/ads GET]', e)
    return NextResponse.json({ error: 'Reklam verisi alınamadı' }, { status: 500 })
  }
}
