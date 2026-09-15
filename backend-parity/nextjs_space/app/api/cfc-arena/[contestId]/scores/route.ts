import { NextRequest, NextResponse } from 'next/server'
import { resolveParams } from '@/lib/parity-route-params'

export const dynamic = 'force-dynamic'

type Ctx = { params: Promise<{ contestId: string }> | { contestId: string } }

export async function GET(_req: NextRequest, context: Ctx) {
  try {
    const { contestId } = await resolveParams(context.params)
    const prisma = (await import('@/lib/db')).default
    const logs = await prisma.cfcScoreLog
      .findMany({
        where: { contestId },
        orderBy: { calculatedAt: 'desc' },
        take: 100,
      })
      .catch(() => [])
    return NextResponse.json({ success: true, items: logs })
  } catch (e) {
    console.error('[cfc-arena/scores]', e)
    return NextResponse.json({ success: true, items: [] })
  }
}
