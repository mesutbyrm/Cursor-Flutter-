import { NextRequest } from 'next/server'
import { postAgencyWalletTransfer } from '@/lib/agency-wallet-handlers'

export const dynamic = 'force-dynamic'

export async function POST(req: NextRequest) {
  return postAgencyWalletTransfer(req)
}
