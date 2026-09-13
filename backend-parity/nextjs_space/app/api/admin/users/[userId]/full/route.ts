import { NextRequest } from 'next/server'
import { resolveParams } from '@/lib/parity-route-params'

export const dynamic = 'force-dynamic'

type Ctx = { params: Promise<{ userId: string }> | { userId: string } }

export async function GET(req: NextRequest, context: Ctx) {
  const { userId } = await resolveParams(context.params)
  const mod = await import('@/app/api/admin/users/[userId]/360/route')
  return mod.GET(req, { params: Promise.resolve({ userId }) })
}
