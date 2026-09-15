import { NextRequest } from 'next/server'
import {
  getAgencyApplications,
  postAgencyApplicationReview,
} from '@/lib/agency-applications-handlers'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  return getAgencyApplications(req)
}

export async function POST(req: NextRequest) {
  return postAgencyApplicationReview(req)
}
