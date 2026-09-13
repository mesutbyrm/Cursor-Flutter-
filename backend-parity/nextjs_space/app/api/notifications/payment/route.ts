import { NextRequest, NextResponse } from 'next/server'
import { authenticateRequest } from '@/lib/mobile-auth'
import prisma from '@/lib/db'

export const dynamic = 'force-dynamic'

const PAYMENT_TYPES = [
  'payment',
  'PAYMENT',
  'cfc_payment',
  'CFC_PAYMENT',
  'jeton_payment',
  'payment_notification',
]

export async function DELETE(req: NextRequest) {
  try {
    const user = await authenticateRequest(req)
    if (!user) {
      return NextResponse.json({ error: 'Oturum açmanız gerekiyor' }, { status: 401 })
    }

    const deleted = await prisma.notification.deleteMany({
      where: {
        userId: user.id,
        OR: PAYMENT_TYPES.map((t) => ({ type: t })),
      },
    })

    return NextResponse.json({
      success: true,
      data: { deleted: deleted.count },
      deleted: deleted.count,
    })
  } catch (e) {
    console.error('[notifications/payment DELETE]', e)
    return NextResponse.json(
      { error: 'Ödeme bildirimleri temizlenemedi' },
      { status: 500 },
    )
  }
}
