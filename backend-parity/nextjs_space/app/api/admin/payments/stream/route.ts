import { NextRequest, NextResponse } from 'next/server'
import { adminPaymentsStream } from '@/lib/parity-admin-handlers'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  try {
    return await adminPaymentsStream(req)
  } catch (e) {
    console.error('[admin/payments/stream GET]', e)
    return NextResponse.json({ error: 'Ödeme akışı başlatılamadı' }, { status: 500 })
  }
}
