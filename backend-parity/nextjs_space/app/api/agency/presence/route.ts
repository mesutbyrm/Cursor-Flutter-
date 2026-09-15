import { NextRequest, NextResponse } from 'next/server'

export const dynamic = 'force-dynamic'

/** Ajans üyelerinin canlı durumu (§19) — üretimde presence servisi ile doldurulur. */
export async function GET(req: NextRequest) {
  try {
    const { requireAuth } = await import('@/lib/rbac')
    const auth = await requireAuth(req)
    if (auth instanceof NextResponse) return auth

    const prisma = (await import('@/lib/db')).default
    const owner = await prisma.agencyUser.findFirst({
      where: { userId: auth.user.id, role: 'owner', isActive: true },
    })
    if (!owner) {
      return NextResponse.json({ success: false, error: 'Yetki yok' }, { status: 403 })
    }

    const members = await prisma.agencyUser.findMany({
      where: { agencyId: owner.agencyId, isActive: true },
      include: { user: { select: { id: true, name: true, username: true, image: true } } },
    })

    const items = members.map((m: { userId: string; user: { name: string; username: string | null } }) => ({
      userId: m.userId,
      name: m.user.name,
      username: m.user.username,
      status: 'offline',
      label: '⚪ Çevrimdışı',
    }))

    return NextResponse.json({ success: true, items })
  } catch (e) {
    console.error('[agency/presence]', e)
    return NextResponse.json({ success: true, items: [], partial: true })
  }
}
