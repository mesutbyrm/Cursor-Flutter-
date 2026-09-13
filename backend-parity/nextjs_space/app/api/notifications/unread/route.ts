import { NextRequest, NextResponse } from 'next/server'
import { authenticateRequest } from '@/lib/mobile-auth'
import prisma from '@/lib/db'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  try {
    const user = await authenticateRequest(req)
    if (!user) {
      return NextResponse.json({ error: 'Oturum açmanız gerekiyor' }, { status: 401 })
    }

    const count = await prisma.notification.count({
      where: { userId: user.id, isRead: false },
    })

    return NextResponse.json({
      success: true,
      data: { count, unreadCount: count, unread: count },
      count,
      unreadCount: count,
    })
  } catch (e) {
    console.error('[notifications/unread GET]', e)
    return NextResponse.json(
      { error: 'Okunmamış bildirim sayısı alınamadı' },
      { status: 500 },
    )
  }
}
