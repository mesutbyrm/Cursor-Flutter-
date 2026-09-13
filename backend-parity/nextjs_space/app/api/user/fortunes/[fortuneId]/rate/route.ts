import { NextRequest, NextResponse } from 'next/server'
import { authenticateRequest } from '@/lib/mobile-auth'
import prisma from '@/lib/db'
import { resolveParams } from '@/lib/parity-route-params'

export const dynamic = 'force-dynamic'

type RouteContext = {
  params: Promise<{ fortuneId: string }> | { fortuneId: string }
}

export async function POST(req: NextRequest, context: RouteContext) {
  try {
    const user = await authenticateRequest(req)
    if (!user) {
      return NextResponse.json({ error: 'Oturum gerekli' }, { status: 401 })
    }
    const { fortuneId } = await resolveParams(context.params)
    const body = await req.json().catch(() => ({}))

    const satisfaction = body.satisfaction ?? body.rating ?? body.stars
    const accuracy = body.accuracy
    const feedback = body.feedback ?? body.comment

    const fortune = await prisma.fortune.findFirst({
      where: { id: fortuneId, userId: user.id },
      select: { id: true },
    })
    if (!fortune) {
      return NextResponse.json({ error: 'Fal kaydı bulunamadı' }, { status: 404 })
    }

    const rating = await prisma.fortuneRating.upsert({
      where: { fortuneId },
      create: {
        fortuneId,
        userId: user.id,
        satisfaction: satisfaction != null ? Number(satisfaction) : null,
        accuracy: accuracy != null ? Number(accuracy) : null,
        feedback: feedback != null ? String(feedback) : null,
      },
      update: {
        satisfaction: satisfaction != null ? Number(satisfaction) : undefined,
        accuracy: accuracy != null ? Number(accuracy) : undefined,
        feedback: feedback != null ? String(feedback) : undefined,
      },
    })

    return NextResponse.json({ success: true, data: rating })
  } catch (e) {
    console.error('[user/fortunes/[fortuneId]/rate POST]', e)
    return NextResponse.json({ error: 'Puan kaydedilemedi' }, { status: 500 })
  }
}
