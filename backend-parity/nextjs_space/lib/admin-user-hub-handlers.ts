import { NextRequest, NextResponse } from 'next/server'

type HubCtx = { userId: string }

async function tryPrisma() {
  try {
    const mod = await import('@/lib/db')
    return mod.default
  } catch {
    return null
  }
}

export async function adminRequireStaff(req: NextRequest): Promise<NextResponse | null> {
  try {
    const { requireAdmin } = await import('@/lib/rbac')
    return await requireAdmin(req)
  } catch {
    return null
  }
}

export async function getAdminUserOverview(_req: NextRequest, { userId }: HubCtx) {
  const prisma = await tryPrisma()
  if (!prisma) {
    return NextResponse.json({
      success: true,
      data: { userId, partial: true, message: 'DB bağlantısı yok — özet stub' },
    })
  }

  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      id: true,
      username: true,
      name: true,
      email: true,
      role: true,
      membership: true,
      membershipExpiresAt: true,
      jetonBalance: true,
      credits: true,
      createdAt: true,
      isBanned: true,
      banReason: true,
      isFrozen: true,
      hiddenFromDiscovery: true,
      canBroadcast: true,
      canCreateRoom: true,
      vipXp: true,
      vipTitle: true,
    },
  })

  if (!user) {
    return NextResponse.json({ success: false, error: 'Kullanıcı bulunamadı' }, { status: 404 })
  }

  const agencyUser = await prisma.agencyUser.findUnique({
    where: { userId },
    include: { agency: { select: { id: true, name: true, status: true } } },
  }).catch(() => null)

  return NextResponse.json({
    success: true,
    data: {
      user,
      agency: agencyUser
        ? {
            agencyId: agencyUser.agencyId,
            role: agencyUser.role,
            agencyName: agencyUser.agency?.name,
            status: agencyUser.agency?.status,
          }
        : null,
      presence: {
        online: false,
        labels: [] as string[],
      },
    },
  })
}

export async function getAdminUserActivity(
  _req: NextRequest,
  { userId }: HubCtx,
  limit = 50,
) {
  const prisma = await tryPrisma()
  if (!prisma) {
    return NextResponse.json({ success: true, items: [], userId })
  }

  const audits = await prisma.auditLog
    .findMany({
      where: { targetId: userId },
      orderBy: { createdAt: 'desc' },
      take: limit,
    })
    .catch(() => [])

  const items = audits.map((a: { action: string; createdAt: Date; description: string | null }) => ({
    type: a.action,
    at: a.createdAt,
    label: a.description ?? a.action,
  }))

  return NextResponse.json({ success: true, items, userId })
}

export async function getAdminUserAgency(_req: NextRequest, { userId }: HubCtx) {
  const prisma = await tryPrisma()
  if (!prisma) {
    return NextResponse.json({ success: true, agency: null, userId })
  }

  const row = await prisma.agencyUser.findUnique({
    where: { userId },
    include: { agency: true },
  })

  return NextResponse.json({
    success: true,
    agency: row
      ? {
          agencyId: row.agencyId,
          role: row.role,
          joinedAt: row.joinedAt,
          agency: row.agency,
        }
      : null,
  })
}

export async function getAdminUserModeration(_req: NextRequest, { userId }: HubCtx) {
  const prisma = await tryPrisma()
  if (!prisma) {
    return NextResponse.json({ success: true, bans: [], warnings: [], userId })
  }

  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { isBanned: true, banReason: true, role: true },
  })

  return NextResponse.json({
    success: true,
    userId,
    isBanned: user?.isBanned ?? false,
    banReason: user?.banReason ?? null,
    warnings: [],
  })
}

export async function getAdminUserReports(_req: NextRequest, { userId }: HubCtx) {
  const prisma = await tryPrisma()
  if (!prisma) {
    return NextResponse.json({ success: true, items: [], userId })
  }

  const reports = await prisma.userReport
    .findMany({
      where: { reportedId: userId },
      orderBy: { createdAt: 'desc' },
      take: 40,
    })
    .catch(() => [])

  return NextResponse.json({ success: true, items: reports, userId })
}

export async function getAdminUserEarnings(
  _req: NextRequest,
  { userId }: HubCtx,
) {
  return NextResponse.json({
    success: true,
    userId,
    items: [],
    message: 'Ledger aggregation — üretimde WalletTransaction filtresi',
  })
}

export async function getAdminUserSpending(
  _req: NextRequest,
  { userId }: HubCtx,
) {
  return NextResponse.json({
    success: true,
    userId,
    items: [],
    message: 'Ledger aggregation — üretimde WalletTransaction filtresi',
  })
}

export async function getAdminUser360(req: NextRequest, { userId }: HubCtx) {
  const denied = await adminRequireStaff(req)
  if (denied) return denied

  const prisma = await tryPrisma()
  if (!prisma) {
    return NextResponse.json({ success: true, userId, partial: true })
  }

  const user = await prisma.user.findUnique({ where: { id: userId } })
  if (!user) {
    return NextResponse.json({ success: false, error: 'Kullanıcı bulunamadı' }, { status: 404 })
  }

  const { password: _pw, ...safe } = user as Record<string, unknown>
  return NextResponse.json({ success: true, ...safe })
}
