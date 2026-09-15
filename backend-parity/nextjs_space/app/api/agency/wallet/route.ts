import { NextRequest } from 'next/server'
import { getAgencyWallet } from '@/lib/agency-wallet-handlers'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  return getAgencyWallet(req)
}
