import { NextRequest, NextResponse } from 'next/server'
import { authenticateRequest } from '@/lib/mobile-auth'
import prisma from '@/lib/db'

export async function requireMobileUser(req: NextRequest) {
  const user = await authenticateRequest(req)
  if (!user) {
    return { user: null, res: NextResponse.json({ error: 'Oturum gerekli' }, { status: 401 }) }
  }
  return { user, res: null as NextResponse | null }
}

export async function referralMe(req: NextRequest) {
  const gate = await requireMobileUser(req)
  if (gate.res) return gate.res
  const user = gate.user!
  const dbUser = await prisma.user.findUnique({
    where: { id: user.id },
    select: {
      id: true,
      referralCode: true,
      username: true,
      name: true,
    },
  })
  const invited = await prisma.referral.count({ where: { referrerId: user.id } })
  const commissions = await prisma.referralCommission.findMany({
    where: { earnerId: user.id },
    orderBy: { createdAt: 'desc' },
    take: 50,
  })

  return NextResponse.json({
    success: true,
    data: {
      user: dbUser,
      referralCode: dbUser?.referralCode,
      invitedCount: invited,
      commissions,
    },
    referralCode: dbUser?.referralCode,
    invitedCount: invited,
  })
}

export async function referralStats(req: NextRequest) {
  const gate = await requireMobileUser(req)
  if (gate.res) return gate.res
  const userId = gate.user!.id
  const invited = await prisma.referral.count({ where: { referrerId: userId } })
  const credits = await prisma.referral.aggregate({
    where: { referrerId: userId },
    _sum: { creditsAwarded: true },
  })
  return NextResponse.json({
    success: true,
    stats: {
      invited,
      totalInvited: invited,
      creditsAwarded: credits._sum.creditsAwarded ?? 0,
    },
    data: { invited, creditsAwarded: credits._sum.creditsAwarded ?? 0 },
  })
}

export async function referralUsers(req: NextRequest) {
  const gate = await requireMobileUser(req)
  if (gate.res) return gate.res
  const rows = await prisma.referral.findMany({
    where: { referrerId: gate.user!.id },
    include: {
      referred: { select: { id: true, name: true, username: true, image: true, createdAt: true } },
    },
    orderBy: { createdAt: 'desc' },
    take: 100,
  })
  return NextResponse.json({ success: true, users: rows, data: rows })
}

export async function referralEarnings(req: NextRequest) {
  const gate = await requireMobileUser(req)
  if (gate.res) return gate.res
  const rows = await prisma.referralCommission.findMany({
    where: { earnerId: gate.user!.id },
    orderBy: { createdAt: 'desc' },
    take: 100,
  })
  return NextResponse.json({ success: true, earnings: rows, data: rows })
}

export async function referralLedger(req: NextRequest) {
  return referralEarnings(req)
}

export async function referralInviteLink(req: NextRequest) {
  const gate = await requireMobileUser(req)
  if (gate.res) return gate.res
  const code =
    (await prisma.user.findUnique({
      where: { id: gate.user!.id },
      select: { referralCode: true },
    }))?.referralCode ?? gate.user!.id
  const link = `https://canlifal.com/register?ref=${encodeURIComponent(code)}`
  return NextResponse.json({
    success: true,
    inviteLink: link,
    link,
    referralCode: code,
    data: { inviteLink: link, referralCode: code },
  })
}

export async function referralSettings(req: NextRequest) {
  const { getCachedPlatformSetting } = await import('@/lib/cache')
  const settings = await getCachedPlatformSetting('referral_commission', {
    enabled: true,
    rate: 0.05,
  })
  return NextResponse.json({ success: true, settings, data: settings })
}
