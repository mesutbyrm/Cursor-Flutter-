import { NextRequest } from 'next/server'
import { getAgencyApplications } from '@/lib/agency-applications-handlers'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  return getAgencyApplications(req)
}
