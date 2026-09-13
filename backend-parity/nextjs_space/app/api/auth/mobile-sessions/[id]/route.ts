import { NextRequest } from 'next/server'
import { DELETE as deleteAuthSession } from '@/app/api/auth/sessions/route'
import { resolveParams } from '@/lib/parity-route-params'

export const dynamic = 'force-dynamic'

type RouteContext = { params: Promise<{ id: string }> | { id: string } }

export async function DELETE(req: NextRequest, context: RouteContext) {
  try {
    const { id } = await resolveParams(context.params)
    const url = new URL(req.url)
    url.pathname = '/api/auth/sessions'
    url.searchParams.set('deviceId', id)
    const forwarded = new NextRequest(url, {
      method: 'DELETE',
      headers: req.headers,
    })
    return deleteAuthSession(forwarded)
  } catch (e) {
    console.error('[auth/mobile-sessions/[id] DELETE]', e)
    const { NextResponse } = await import('next/server')
    return NextResponse.json({ error: 'Oturum sonlandırılamadı' }, { status: 500 })
  }
}
