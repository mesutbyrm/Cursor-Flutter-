import { NextRequest } from 'next/server'
import { getSocialActions } from '@/lib/social-discovery-handlers'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  return getSocialActions(req)
}
