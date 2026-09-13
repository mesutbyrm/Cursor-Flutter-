import { NextRequest } from 'next/server'

export function rewritePath(req: NextRequest, pathname: string, search?: URLSearchParams) {
  const url = new URL(req.url)
  url.pathname = pathname
  if (search) {
    url.search = search.toString()
  }
  return new NextRequest(url, {
    method: req.method,
    headers: req.headers,
    body: req.body,
    duplex: 'half',
  } as RequestInit & { duplex?: 'half' })
}
