import { NextRequest, NextResponse } from 'next/server'

export const dynamic = 'force-dynamic'

export async function GET(_req: NextRequest) {
  try {
    const prisma = (await import('@/lib/db')).default
    const contests = await prisma.cfcContest
      .findMany({
        where: { status: 'active' },
        orderBy: { startsAt: 'desc' },
        take: 30,
      })
      .catch(() => [])
    return NextResponse.json({ success: true, contests, items: contests })
  } catch {
    return NextResponse.json({ success: true, contests: [], items: [] })
  }
}
