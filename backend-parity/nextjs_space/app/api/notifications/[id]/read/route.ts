import { NextRequest, NextResponse } from 'next/server'
import { authenticateRequest } from '@/lib/mobile-auth'
import prisma from '@/lib/db'

export const dynamic = 'force-dynamic'

type RouteContext = { params: Promise<{ id: string }> | { id: string } }

async function resolveId(params: RouteContext['params']): Promise<string> {
  const p = await Promise.resolve(params)
  return p.id
}

export async function PATCH(req: NextRequest, context: RouteContext) {
  try {
    const user = await authenticateRequest(req)
    if (!user) {
      return NextResponse.json({ error: 'Oturum açmanız gerekiyor' }, { status: 401 })
    }

    const id = await resolveId(context.params)
    const result = await prisma.notification.updateMany({
      where: { id, userId: user.id },
      data: { isRead: true },
    })

    if (result.count === 0) {
      return NextResponse.json({ error: 'Bildirim bulunamadı' }, { status: 404 })
    }

    return NextResponse.json({ success: true, data: { id, read: true } })
  } catch (e) {
    console.error('[notifications/[id]/read PATCH]', e)
    return NextResponse.json({ error: 'Bildirim okundu işaretlenemedi' }, { status: 500 })
  }
}

export async function POST(req: NextRequest, context: RouteContext) {
  return PATCH(req, context)
}
