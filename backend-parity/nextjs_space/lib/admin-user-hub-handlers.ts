import { NextRequest, NextResponse } from 'next/server'

import { hubRangeSince } from '@/lib/hub-date-range'

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

  const labels: string[] = []
  if (user.isBanned) labels.push('🔴 Banlı')
  if (user.isFrozen) labels.push('🧊 Dondurulmuş')
  if (user.hiddenFromDiscovery) labels.push('🙈 Keşfet gizli')
  if (!user.canBroadcast) labels.push('📺 Yayın kapalı')
  if (!user.canCreateRoom) labels.push('🎙 Oda kapalı')

  const live = await prisma.videoStream
    .findFirst({ where: { userId, status: 'live' }, select: { id: true, title: true } })
    .catch(() => null)
  if (live) labels.push('📺 Canlı yayında')

  const teller = await prisma.liveFortuneTeller
    .findFirst({ where: { userId }, select: { id: true, isOnline: true } })
    .catch(() => null)
  if (teller?.isOnline) labels.push('🔮 Canlı falcı')

  if (agencyUser && (agencyUser as { isActive?: boolean }).isActive !== false) {
    labels.push('🏢 Ajans üyesi')
  }

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
        online: labels.some((l) => l.includes('Canlı')),
        labels,
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
    select: {
      isBanned: true,
      banReason: true,
      bannedAt: true,
      bannedUntil: true,
      role: true,
      isFrozen: true,
      frozenReason: true,
      warningCount: true,
      canBroadcast: true,
      canCreateRoom: true,
      canChat: true,
      hiddenFromDiscovery: true,
    },
  })

  const actions = await prisma.adminUserAction
    .findMany({
      where: { targetUserId: userId },
      orderBy: { createdAt: 'desc' },
      take: 30,
    })
    .catch(() => [])

  return NextResponse.json({
    success: true,
    userId,
    isBanned: user?.isBanned ?? false,
    banReason: user?.banReason ?? null,
    isFrozen: user?.isFrozen ?? false,
    warningCount: user?.warningCount ?? 0,
    user,
    warnings: actions,
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

export async function getAdminUserEarnings(req: NextRequest, { userId }: HubCtx) {
  const prisma = await tryPrisma()
  if (!prisma) {
    return NextResponse.json({ success: true, userId, items: [] })
  }
  const since = hubRangeSince(req)
  const whereJeton: Record<string, unknown> = { userId, amount: { gt: 0 } }
  const whereCredit: Record<string, unknown> = { userId, amount: { gt: 0 } }
  if (since) {
    whereJeton.createdAt = { gte: since }
    whereCredit.createdAt = { gte: since }
  }

  const [jetonRows, creditRows] = await Promise.all([
    prisma.jetonTransaction.findMany({
      where: whereJeton,
      orderBy: { createdAt: 'desc' },
      take: 100,
    }),
    prisma.creditTransaction.findMany({
      where: whereCredit,
      orderBy: { createdAt: 'desc' },
      take: 100,
    }),
  ])

  const items = [
    ...jetonRows.map((r: { id: string; amount: number; type: string; description: string | null; createdAt: Date; balanceAfter: number }) => ({
      id: r.id,
      currency: 'jeton',
      amount: r.amount,
      type: r.type,
      description: r.description,
      createdAt: r.createdAt,
      balanceAfter: r.balanceAfter,
    })),
    ...creditRows.map((r: { id: string; amount: number; type: string; description: string | null; createdAt: Date; balance: number }) => ({
      id: r.id,
      currency: 'credit',
      amount: r.amount,
      type: r.type,
      description: r.description,
      createdAt: r.createdAt,
      balanceAfter: r.balance,
    })),
  ].sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())

  return NextResponse.json({ success: true, userId, items, range: req.nextUrl.searchParams.get('range') ?? 'all' })
}

export async function getAdminUserSpending(req: NextRequest, { userId }: HubCtx) {
  const prisma = await tryPrisma()
  if (!prisma) {
    return NextResponse.json({ success: true, userId, items: [] })
  }
  const since = hubRangeSince(req)
  const whereJeton: Record<string, unknown> = { userId, amount: { lt: 0 } }
  const whereCredit: Record<string, unknown> = { userId, amount: { lt: 0 } }
  if (since) {
    whereJeton.createdAt = { gte: since }
    whereCredit.createdAt = { gte: since }
  }

  const [jetonRows, creditRows] = await Promise.all([
    prisma.jetonTransaction.findMany({
      where: whereJeton,
      orderBy: { createdAt: 'desc' },
      take: 100,
    }),
    prisma.creditTransaction.findMany({
      where: whereCredit,
      orderBy: { createdAt: 'desc' },
      take: 100,
    }),
  ])

  const items = [
    ...jetonRows.map((r: { id: string; amount: number; type: string; description: string | null; createdAt: Date; balanceAfter: number }) => ({
      id: r.id,
      currency: 'jeton',
      amount: r.amount,
      type: r.type,
      description: r.description,
      createdAt: r.createdAt,
      balanceAfter: r.balanceAfter,
    })),
    ...creditRows.map((r: { id: string; amount: number; type: string; description: string | null; createdAt: Date; balance: number }) => ({
      id: r.id,
      currency: 'credit',
      amount: r.amount,
      type: r.type,
      description: r.description,
      createdAt: r.createdAt,
      balanceAfter: r.balance,
    })),
  ].sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())

  return NextResponse.json({ success: true, userId, items, range: req.nextUrl.searchParams.get('range') ?? 'all' })
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
