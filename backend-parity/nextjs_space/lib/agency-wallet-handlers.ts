import { NextRequest, NextResponse } from 'next/server'

async function tryPrisma() {
  try {
    const mod = await import('@/lib/db')
    return mod.default
  } catch {
    return null
  }
}

async function resolveAgencyForOwner(userId: string) {
  const prisma = await tryPrisma()
  if (!prisma) return null
  const membership = await prisma.agencyUser.findFirst({
    where: { userId, role: 'owner', isActive: true },
    include: { agency: { include: { wallet: true } } },
  })
  return membership
}

export async function getAgencyWallet(req: NextRequest) {
  try {
    const { requireAuth } = await import('@/lib/rbac')
    const auth = await requireAuth(req)
    if (auth instanceof NextResponse) return auth

    const row = await resolveAgencyForOwner(auth.user.id)
    if (!row) {
      return NextResponse.json(
        { success: false, error: 'Ajans sahibi değilsiniz' },
        { status: 403 },
      )
    }

    const wallet = row.agency.wallet
    return NextResponse.json({
      success: true,
      data: {
        agencyId: row.agencyId,
        wallet: wallet ?? { jetonBalance: 0, totalBonus: 0 },
      },
    })
  } catch (e) {
    console.error('[agency/wallet GET]', e)
    return NextResponse.json({ success: true, data: { wallet: null, partial: true } })
  }
}

export async function postAgencyWalletTransfer(req: NextRequest) {
  try {
    const { requireAuth } = await import('@/lib/rbac')
    const auth = await requireAuth(req)
    if (auth instanceof NextResponse) return auth

    const body = await req.json().catch(() => ({}))
    const targetUserId = String(body.userId ?? '').trim()
    const amount = Number(body.amount)
    const reason = String(body.reason ?? '').trim()
    const idempotencyKey = String(
      body.idempotencyKey ?? req.headers.get('idempotency-key') ?? '',
    ).trim()

    if (!targetUserId || !Number.isFinite(amount) || amount <= 0) {
      return NextResponse.json({ success: false, error: 'Geçersiz miktar veya kullanıcı' }, { status: 400 })
    }

    const prisma = await tryPrisma()
    if (!prisma) {
      return NextResponse.json({ success: false, error: 'DB yok' }, { status: 503 })
    }

    const owner = await resolveAgencyForOwner(auth.user.id)
    if (!owner) {
      return NextResponse.json({ success: false, error: 'Yetki yok' }, { status: 403 })
    }

    const member = await prisma.agencyUser.findFirst({
      where: { agencyId: owner.agencyId, userId: targetUserId, isActive: true },
    })
    if (!member) {
      return NextResponse.json(
        { success: false, error: 'Kullanıcı ajans üyesi değil' },
        { status: 403 },
      )
    }

    if (idempotencyKey) {
      const dup = await prisma.agencyWalletTransaction.findFirst({
        where: { idempotencyKey },
      })
      if (dup) {
        return NextResponse.json({ success: true, duplicate: true, transactionId: dup.id })
      }
    }

    const result = await prisma.$transaction(async (tx: any) => {
      const wallet = await tx.agencyWallet.findUnique({
        where: { agencyId: owner.agencyId },
      })
      if (!wallet || wallet.isLocked) {
        throw new Error('WALLET_LOCKED')
      }
      if (wallet.jetonBalance < amount) {
        throw new Error('INSUFFICIENT')
      }

      const balanceBefore = wallet.jetonBalance
      const balanceAfter = balanceBefore - amount

      await tx.agencyWallet.update({
        where: { agencyId: owner.agencyId },
        data: {
          jetonBalance: balanceAfter,
          totalTransferred: { increment: amount },
        },
      })

      await tx.user.update({
        where: { id: targetUserId },
        data: { jetonBalance: { increment: amount } },
      })

      const txn = await tx.agencyWalletTransaction.create({
        data: {
          agencyId: owner.agencyId,
          type: 'transfer',
          direction: 'debit',
          amount,
          balanceBefore,
          balanceAfter,
          targetUserId,
          actorId: auth.user.id,
          actorRole: auth.user.role,
          reason: reason || null,
          idempotencyKey: idempotencyKey || null,
        },
      })

      return txn
    })

    try {
      const { recordAudit } = await import('@/lib/audit-log')
      await recordAudit({
        actorId: auth.user.id,
        actorRole: auth.user.role,
        action: 'agency.wallet.transfer',
        targetType: 'user',
        targetId: targetUserId,
        description: reason || `Ajans jeton transfer: ${amount}`,
        metadata: { agencyId: owner.agencyId, amount, transactionId: result.id },
      })
    } catch {
      /* audit optional in parity */
    }

    return NextResponse.json({
      success: true,
      transactionId: result.id,
      balanceAfter: result.balanceAfter,
    })
  } catch (e: any) {
    const msg = String(e?.message ?? e)
    if (msg.includes('INSUFFICIENT')) {
      return NextResponse.json({ success: false, error: 'Yetersiz ajans bakiyesi' }, { status: 400 })
    }
    if (msg.includes('WALLET_LOCKED')) {
      return NextResponse.json({ success: false, error: 'Cüzdan kilitli' }, { status: 403 })
    }
    console.error('[agency/wallet/transfer]', e)
    return NextResponse.json({ success: false, error: 'Transfer başarısız' }, { status: 500 })
  }
}
