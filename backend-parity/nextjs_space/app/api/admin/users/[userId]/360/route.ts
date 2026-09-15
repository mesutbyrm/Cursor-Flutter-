import { NextRequest } from 'next/server'
import { resolveParams } from '@/lib/parity-route-params'
import { getAdminUser360 } from '@/lib/admin-user-hub-handlers'

export const dynamic = 'force-dynamic'

type Ctx = { params: Promise<{ userId: string }> | { userId: string } }

export async function GET(req: NextRequest, context: Ctx) {
  const { userId } = await resolveParams(context.params)
  return getAdminUser360(req, { userId })
}
