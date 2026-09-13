import { NextRequest, NextResponse } from 'next/server'
import { authenticateRequest } from '@/lib/mobile-auth'
import prisma from '@/lib/db'
import { resolveParams } from '@/lib/parity-route-params'

export const dynamic = 'force-dynamic'

type RouteContext = {
  params: Promise<{ fortuneId: string }> | { fortuneId: string }
}

export async function POST(req: NextRequest, context: RouteContext) {
  return setPinned(req, context, true)
}

export async function PATCH(req: NextRequest, context: RouteContext) {
  const body = await req.json().catch(() => ({}))
  const pinned = body.pinned !== false && body.isPinned !== false
  return setPinned(req, context, pinned)
}

async function setPinned(
  req: NextRequest,
  context: RouteContext,
  pinned: boolean,
) {
  try {
    const user = await authenticateRequest(req)
    if (!user) {
      return NextResponse.json({ error: 'Oturum gerekli' }, { status: 401 })
    }
    const { fortuneId } = await resolveParams(context.params)

    const updated = await prisma.fortune.updateMany({
      where: { id: fortuneId, userId: user.id },
      data: {
        isPinned: pinned,
        pinnedAt: pinned ? new Date() : null,
      },
    })

    if (updated.count === 0) {
      return NextResponse.json({ error: 'Fal kaydı bulunamadı' }, { status: 404 })
    }

    return NextResponse.json({ success: true, data: { id: fortuneId, pinned } })
  } catch (e) {
    console.error('[user/fortunes/[fortuneId]/pin]', e)
    return NextResponse.json({ error: 'Sabitleme güncellenemedi' }, { status: 500 })
  }
}
