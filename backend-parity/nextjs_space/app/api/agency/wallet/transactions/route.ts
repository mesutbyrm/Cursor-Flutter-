import { NextRequest, NextResponse } from 'next/server'

export const dynamic = 'force-dynamic'

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

    const limit = Math.min(Number(req.nextUrl.searchParams.get('limit') ?? '50'), 100)
    const txns = await prisma.agencyWalletTransaction.findMany({
      where: { agencyId: owner.agencyId },
      orderBy: { createdAt: 'desc' },
      take: limit,
    })

    return NextResponse.json({ success: true, items: txns })
  } catch (e) {
    console.error('[agency/wallet/transactions]', e)
    return NextResponse.json({ success: true, items: [] })
  }
}
