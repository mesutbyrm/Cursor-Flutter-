import { NextRequest, NextResponse } from 'next/server'
import { resolveParams } from '@/lib/parity-route-params'

export const dynamic = 'force-dynamic'

type Ctx = { params: Promise<{ contestId: string }> | { contestId: string } }

export async function GET(_req: NextRequest, context: Ctx) {
  try {
    const { contestId } = await resolveParams(context.params)
    const prisma = (await import('@/lib/db')).default
    const contest = await prisma.cfcContest.findUnique({
      where: { id: contestId },
      include: {
        participants: { take: 50, orderBy: { score: 'desc' } },
      },
    })
    if (!contest) {
      return NextResponse.json({ success: false, error: 'Bulunamadı' }, { status: 404 })
    }
    return NextResponse.json({ success: true, contest })
  } catch (e) {
    console.error('[cfc-arena/[contestId]]', e)
    return NextResponse.json({ success: false, error: 'Yüklenemedi' }, { status: 500 })
  }
}
