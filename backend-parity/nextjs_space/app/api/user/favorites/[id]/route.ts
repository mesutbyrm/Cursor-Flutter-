import { NextRequest, NextResponse } from 'next/server'
import { authenticateRequest } from '@/lib/mobile-auth'
import prisma from '@/lib/db'
import { resolveParams } from '@/lib/parity-route-params'

export const dynamic = 'force-dynamic'

const favorites = () => (prisma as any).userContentFavorite

type RouteContext = { params: Promise<{ id: string }> | { id: string } }

export async function DELETE(req: NextRequest, context: RouteContext) {
  try {
    const user = await authenticateRequest(req)
    if (!user) {
      return NextResponse.json({ error: 'Oturum gerekli' }, { status: 401 })
    }
    const { id } = await resolveParams(context.params)

    const deleted = await favorites().deleteMany({
      where: { id, userId: user.id },
    })

    if (deleted.count === 0) {
      return NextResponse.json({ error: 'Favori bulunamadı' }, { status: 404 })
    }

    return NextResponse.json({ success: true })
  } catch (e) {
    console.error('[user/favorites/[id] DELETE]', e)
    return NextResponse.json({ error: 'Favori silinemedi' }, { status: 500 })
  }
}
