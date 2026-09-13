import { NextRequest, NextResponse } from 'next/server'
import { adminUserSubresourceEmpty } from '@/lib/parity-admin-handlers'

export const dynamic = 'force-dynamic'

export async function GET(_req: NextRequest) {
  try {
    return await adminUserSubresourceEmpty(_req, 'gifts')
  } catch (e) {
    console.error('[admin/users/[userId]/gifts GET]', e)
    return NextResponse.json({ error: 'Hediye geçmişi alınamadı' }, { status: 500 })
  }
}
