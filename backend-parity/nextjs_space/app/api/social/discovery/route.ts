import { NextRequest } from 'next/server'
import { getSocialDiscovery } from '@/lib/social-discovery-handlers'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  return getSocialDiscovery(req)
}
