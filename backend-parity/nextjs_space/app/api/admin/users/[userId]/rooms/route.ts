import { NextRequest, NextResponse } from 'next/server'
import { adminUserSubresourceEmpty } from '@/lib/parity-admin-handlers'

export const dynamic = 'force-dynamic'

export async function GET(_req: NextRequest) {
  try {
    return await adminUserSubresourceEmpty(_req, 'rooms')
  } catch (e) {
    console.error('[admin/users/[userId]/rooms GET]', e)
    return NextResponse.json({ error: 'Odalar alınamadı' }, { status: 500 })
  }
}
