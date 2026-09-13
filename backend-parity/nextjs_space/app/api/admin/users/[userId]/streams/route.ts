import { NextRequest, NextResponse } from 'next/server'
import { adminUserSubresourceEmpty } from '@/lib/parity-admin-handlers'

export const dynamic = 'force-dynamic'

export async function GET(_req: NextRequest) {
  try {
    return await adminUserSubresourceEmpty(_req, 'streams')
  } catch (e) {
    console.error('[admin/users/[userId]/streams GET]', e)
    return NextResponse.json({ error: 'Yayınlar alınamadı' }, { status: 500 })
  }
}
