import { NextRequest, NextResponse } from 'next/server'

export const dynamic = 'force-dynamic'

export async function POST(req: NextRequest) {
  try {
    const { requireAuth } = await import('@/lib/rbac')
    const auth = await requireAuth(req)
    if (auth instanceof NextResponse) return auth

    const body = await req.json().catch(() => ({}))
    const contestId = String(body.contestId ?? '').trim()
    if (!contestId) {
      return NextResponse.json({ success: false, error: 'contestId gerekli' }, { status: 400 })
    }

    const prisma = (await import('@/lib/db')).default
    const contest = await prisma.cfcContest.findUnique({ where: { id: contestId } })
    if (!contest || contest.status !== 'active') {
      return NextResponse.json({ success: false, error: 'Yarışma aktif değil' }, { status: 400 })
    }

    const existing = await prisma.cfcParticipant.findFirst({
      where: { contestId, userId: auth.user.id },
    })
    if (existing) {
      return NextResponse.json({ success: true, participantId: existing.id, alreadyJoined: true })
    }

    const participant = await prisma.cfcParticipant.create({
      data: {
        contestId,
        userId: auth.user.id,
        status: 'active',
      },
    })

    return NextResponse.json({ success: true, participantId: participant.id })
  } catch (e) {
    console.error('[cfc-arena/join]', e)
    return NextResponse.json({ success: false, error: 'Katılım başarısız' }, { status: 500 })
  }
}
