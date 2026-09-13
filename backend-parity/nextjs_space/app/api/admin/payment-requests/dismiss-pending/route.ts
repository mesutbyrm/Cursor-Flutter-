import { NextRequest, NextResponse } from 'next/server'
import { adminPaymentDismissPending } from '@/lib/parity-admin-handlers'

export const dynamic = 'force-dynamic'

export async function POST(req: NextRequest) {
  try {
    return await adminPaymentDismissPending(req)
  } catch (e) {
    console.error('[admin/payment-requests/dismiss-pending POST]', e)
    return NextResponse.json({ error: 'Bekleyen ödeme kapatılamadı' }, { status: 500 })
  }
}
