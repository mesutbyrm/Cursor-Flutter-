import { NextRequest, NextResponse } from 'next/server'

async function tryPrisma() {
  try {
    const mod = await import('@/lib/db')
    return mod.default
  } catch {
    return null
  }
}

async function resolveAgencyLead(userId: string) {
  const prisma = await tryPrisma()
  if (!prisma) return null
  const membership = await prisma.agencyUser.findFirst({
    where: {
      userId,
      isActive: true,
      role: { in: ['owner', 'manager'] },
    },
    include: { agency: true },
  })
  return membership
}

/** `GET /api/agency/applications` — bekleyen üye/çıkış talepleri (ajans yöneticisi). */
export async function getAgencyApplications(req: NextRequest) {
  try {
    const { requireAuth } = await import('@/lib/rbac')
    const auth = await requireAuth(req)
    if (auth instanceof NextResponse) return auth

    const lead = await resolveAgencyLead(auth.user.id)
    if (!lead) {
      return NextResponse.json(
        { success: false, error: 'Ajans yöneticisi değilsiniz' },
        { status: 403 },
      )
    }

    const prisma = await tryPrisma()
    if (!prisma) {
      return NextResponse.json({
        success: true,
        data: { items: [], partial: true },
      })
    }

    const leaveRows = await prisma.agencyLeaveRequest
      .findMany({
        where: { agencyId: lead.agencyId, status: 'pending' },
        orderBy: { createdAt: 'desc' },
        take: 50,
        include: {
          user: {
            select: {
              id: true,
              username: true,
              name: true,
              image: true,
            },
          },
        },
      })
      .catch(() => [])

    const items = leaveRows.map((row) => ({
      id: row.id,
      type: 'leave_request',
      status: row.status,
      userId: row.userId,
      displayName: row.user?.name ?? row.user?.username ?? row.userId,
      username: row.user?.username,
      avatarUrl: row.user?.image,
      reason: row.reason,
      createdAt: row.createdAt,
    }))

    return NextResponse.json({
      success: true,
      data: { items, agencyId: lead.agencyId },
    })
  } catch (e) {
    console.error('[agency/applications GET]', e)
    return NextResponse.json({ success: true, data: { items: [] } })
  }
}

/** `POST /api/agency/applications` — çıkış talebi onay / red. */
export async function postAgencyApplicationReview(req: NextRequest) {
  try {
    const { requireAuth } = await import('@/lib/rbac')
    const auth = await requireAuth(req)
    if (auth instanceof NextResponse) return auth

    const lead = await resolveAgencyLead(auth.user.id)
    if (!lead) {
      return NextResponse.json(
        { success: false, error: 'Ajans yöneticisi değilsiniz' },
        { status: 403 },
      )
    }

    const body = await req.json().catch(() => ({}))
    const id = String(body.id ?? body.requestId ?? '').trim()
    const action = String(body.action ?? body.decision ?? '').trim().toLowerCase()
    const note = String(body.note ?? body.reviewNote ?? '').trim()

    if (!id || !['approve', 'reject', 'approved', 'rejected'].includes(action)) {
      return NextResponse.json(
        { success: false, error: 'id ve action (approve|reject) gerekli' },
        { status: 400 },
      )
    }

    const prisma = await tryPrisma()
    if (!prisma) {
      return NextResponse.json({ success: false, error: 'DB yok' }, { status: 503 })
    }

    const row = await prisma.agencyLeaveRequest.findFirst({
      where: { id, agencyId: lead.agencyId, status: 'pending' },
    })
    if (!row) {
      return NextResponse.json({ success: false, error: 'Talep bulunamadı' }, { status: 404 })
    }

    const approved = action === 'approve' || action === 'approved'
    const status = approved ? 'approved' : 'rejected'

    await prisma.agencyLeaveRequest.update({
      where: { id },
      data: {
        status,
        reviewedBy: auth.user.id,
        reviewNote: note || null,
        reviewedAt: new Date(),
      },
    })

    if (approved) {
      await prisma.agencyUser.updateMany({
        where: { agencyId: lead.agencyId, userId: row.userId },
        data: { isActive: false, leftAt: new Date() },
      })
    }

    return NextResponse.json({ success: true, status })
  } catch (e) {
    console.error('[agency/applications POST]', e)
    return NextResponse.json({ success: false, error: 'İşlem başarısız' }, { status: 500 })
  }
}
