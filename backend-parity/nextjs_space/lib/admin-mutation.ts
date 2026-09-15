/**
 * P0 — Kritik admin mutasyonları (parity kopyası).
 * Üretim: backend-reference/canlifal_flutter_paketi/kaynak/lib/admin-mutation.ts ile senkron tutun.
 */

import { NextRequest, NextResponse } from 'next/server'

export type AdminMutationContext = {
  req: NextRequest
  actor: { id: string; role: string }
  permission: string
  action: string
  targetType: string
  targetId: string
  reason: string
  before?: Record<string, unknown> | null
  after?: Record<string, unknown> | null
  idempotencyKey?: string | null
}

const idempotencyCache = new Map<string, { at: number; response: unknown }>()
const IDEM_TTL_MS = 24 * 60 * 60 * 1000

function idempotencyHit(key: string): unknown | null {
  const row = idempotencyCache.get(key)
  if (!row) return null
  if (Date.now() - row.at > IDEM_TTL_MS) {
    idempotencyCache.delete(key)
    return null
  }
  return row.response
}

function idempotencyStore(key: string, response: unknown) {
  idempotencyCache.set(key, { at: Date.now(), response })
}

async function recordAuditSafe(ctx: AdminMutationContext) {
  try {
    const { recordAudit, getAuditIp } = await import('@/lib/audit-log')
    await recordAudit({
      actorId: ctx.actor.id,
      actorRole: ctx.actor.role,
      action: ctx.action,
      targetType: ctx.targetType,
      targetId: ctx.targetId,
      before: ctx.before ?? null,
      after: ctx.after ?? null,
      description: ctx.reason,
      metadata: { idempotencyKey: ctx.idempotencyKey },
      ip: getAuditIp(ctx.req),
    })
  } catch {
    console.info('[admin-mutation] audit', ctx.action, ctx.targetId)
  }
}

export async function guardAdminMutation(
  req: NextRequest,
  opts: {
    permission: string
    action: string
    targetType: string
    targetId: string
    requireReason?: boolean
  },
): Promise<
  | { ok: true; actor: { id: string; role: string }; reason: string; idempotencyKey: string | null }
  | NextResponse
> {
  const { requireAuth } = await import('@/lib/rbac')
  const auth = await requireAuth(req)
  if (auth instanceof NextResponse) return auth

  try {
    const { hasPermission } = await import('@/lib/permissions')
    const allowed = await hasPermission(auth.user.role, opts.permission, auth.user.id)
    if (!allowed) {
      return NextResponse.json({ success: false, error: 'Yetki yok' }, { status: 403 })
    }
  } catch {
    const role = auth.user.role?.toLowerCase() ?? ''
    if (!['admin', 'superadmin', 'owner', 'moderator'].includes(role)) {
      return NextResponse.json({ success: false, error: 'Yetki yok' }, { status: 403 })
    }
  }

  const body = await req.clone().json().catch(() => ({}))
  const reason = String(body.reason ?? body.note ?? '').trim()
  if (opts.requireReason !== false && reason.length < 3) {
    return NextResponse.json(
      { success: false, error: 'İşlem nedeni zorunludur (min 3 karakter)' },
      { status: 400 },
    )
  }

  const idempotencyKey =
    req.headers.get('idempotency-key') ||
    (body.idempotencyKey as string | undefined) ||
    null

  if (idempotencyKey) {
    const cached = idempotencyHit(idempotencyKey)
    if (cached) {
      return NextResponse.json(cached)
    }
  }

  return {
    ok: true,
    actor: auth.user,
    reason,
    idempotencyKey,
  }
}

export async function completeAdminMutation(
  ctx: AdminMutationContext,
  result: Record<string, unknown>,
): Promise<NextResponse> {
  await recordAuditSafe(ctx)
  const payload = { success: true, ...result }
  if (ctx.idempotencyKey) {
    idempotencyStore(ctx.idempotencyKey, payload)
  }
  return NextResponse.json(payload)
}
