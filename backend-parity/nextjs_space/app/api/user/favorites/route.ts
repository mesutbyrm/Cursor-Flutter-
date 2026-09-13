import { NextRequest, NextResponse } from 'next/server'
import { authenticateRequest } from '@/lib/mobile-auth'
import prisma from '@/lib/db'

export const dynamic = 'force-dynamic'

// Prisma model: user_content_favorites (bkz. backend-parity/prisma-additive/)
const favorites = () => (prisma as any).userContentFavorite

export async function GET(req: NextRequest) {
  try {
    const user = await authenticateRequest(req)
    if (!user) {
      return NextResponse.json({ error: 'Oturum gerekli' }, { status: 401 })
    }
    const rows = await favorites().findMany({
      where: { userId: user.id },
      orderBy: { createdAt: 'desc' },
    })
    return NextResponse.json({ success: true, favorites: rows, data: rows })
  } catch (e) {
    console.error('[user/favorites GET]', e)
    return NextResponse.json({ error: 'Favoriler alınamadı' }, { status: 500 })
  }
}

export async function POST(req: NextRequest) {
  try {
    const user = await authenticateRequest(req)
    if (!user) {
      return NextResponse.json({ error: 'Oturum gerekli' }, { status: 401 })
    }
    const body = await req.json().catch(() => ({}))
    const targetType = String(body.targetType ?? body.type ?? '').trim()
    const targetId = String(body.targetId ?? body.refId ?? '').trim()
    if (!targetType || !targetId) {
      return NextResponse.json(
        { error: 'targetType ve targetId zorunludur' },
        { status: 400 },
      )
    }

    const row = await favorites().upsert({
      where: {
        userId_targetType_targetId: {
          userId: user.id,
          targetType,
          targetId,
        },
      },
      create: {
        userId: user.id,
        targetType,
        targetId,
        title: body.title ?? null,
        url: body.url ?? null,
        imageUrl: body.imageUrl ?? null,
      },
      update: {
        title: body.title ?? undefined,
        url: body.url ?? undefined,
        imageUrl: body.imageUrl ?? undefined,
      },
    })

    return NextResponse.json({ success: true, data: row })
  } catch (e) {
    console.error('[user/favorites POST]', e)
    return NextResponse.json({ error: 'Favori eklenemedi' }, { status: 500 })
  }
}
