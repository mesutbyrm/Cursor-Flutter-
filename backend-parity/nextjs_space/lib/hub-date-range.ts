import { NextRequest } from 'next/server'

export function hubRangeSince(req: NextRequest): Date | null {
  const range = (req.nextUrl.searchParams.get('range') ?? 'all').toLowerCase()
  const now = new Date()
  switch (range) {
    case 'today':
      return new Date(now.getFullYear(), now.getMonth(), now.getDate())
    case '7d':
      return new Date(now.getTime() - 7 * 86400000)
    case '30d':
      return new Date(now.getTime() - 30 * 86400000)
    case '90d':
      return new Date(now.getTime() - 90 * 86400000)
    default:
      return null
  }
}
