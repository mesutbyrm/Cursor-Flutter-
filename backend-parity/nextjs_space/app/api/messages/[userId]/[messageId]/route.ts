import { NextRequest, NextResponse } from 'next/server'
import { authenticateRequest } from '@/lib/mobile-auth'
import prisma from '@/lib/db'
import { resolveParams } from '@/lib/parity-route-params'

export const dynamic = 'force-dynamic'

type RouteContext = {
  params: Promise<{ userId: string; messageId: string }> | {
    userId: string
    messageId: string
  }
}

export async function DELETE(req: NextRequest, context: RouteContext) {
  try {
    const user = await authenticateRequest(req)
    if (!user) {
      return NextResponse.json({ error: 'Oturum gerekli' }, { status: 401 })
    }
    const { userId: peerUserId, messageId } = await resolveParams(context.params)

    const deleted = await prisma.directMessage.deleteMany({
      where: {
        id: messageId,
        senderId: user.id,
        receiverId: peerUserId,
      },
    })

    if (deleted.count === 0) {
      return NextResponse.json({ error: 'Mesaj bulunamadı' }, { status: 404 })
    }

    return NextResponse.json({ success: true })
  } catch (e) {
    console.error('[messages/[userId]/[messageId] DELETE]', e)
    return NextResponse.json({ error: 'Mesaj silinemedi' }, { status: 500 })
  }
}
