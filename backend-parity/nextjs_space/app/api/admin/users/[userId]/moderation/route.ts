import { NextRequest } from 'next/server'
import { resolveParams } from '@/lib/parity-route-params'
import { adminRequireStaff, getAdminUserModeration } from '@/lib/admin-user-hub-handlers'

export const dynamic = 'force-dynamic'

type Ctx = { params: Promise<{ userId: string }> | { userId: string } }

export async function GET(req: NextRequest, context: Ctx) {
  const denied = await adminRequireStaff(req)
  if (denied) return denied
  const { userId } = await resolveParams(context.params)
  return getAdminUserModeration(req, { userId })
}
