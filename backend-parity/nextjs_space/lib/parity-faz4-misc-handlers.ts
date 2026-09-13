import { NextRequest, NextResponse } from 'next/server'
import { getCachedPlatformSetting } from '@/lib/cache'

const GIFT_DISPLAY_FALLBACK = {
  enabled: true,
  durationMs: 3000,
  position: 'topCenter',
  size: 'small',
  maxQueue: 10,
  animation: 'slide',
  showSender: true,
  showReceiver: false,
  showGiftName: true,
  showAmount: true,
  showGiftIcon: true,
  maxVisible: 1,
  backgroundOpacity: 0.85,
  soundEnabled: true,
}

export async function giftsDisplaySettings(_req: NextRequest) {
  const settings = await getCachedPlatformSetting('gift_display_settings', GIFT_DISPLAY_FALLBACK)
  return NextResponse.json({ success: true, ...settings, data: settings })
}

export async function siteAnimationsActive(_req: NextRequest) {
  try {
    const mod = await import('@/app/api/animations/manifest/route')
    const res = await mod.GET(_req)
    return res
  } catch {
    const catalog = await getCachedPlatformSetting('site_animations_active', {
      animations: {},
      version: 1,
    })
    return NextResponse.json({ success: true, ...catalog, data: catalog })
  }
}

export async function fortuneAccessConsume(req: NextRequest) {
  const body = await req.json().catch(() => ({}))
  const fortuneType =
    (body as { slug?: string; fortuneType?: string }).slug ??
    (body as { fortuneType?: string }).fortuneType ??
    'general'
  const forwarded = new NextRequest(req.url, {
    method: 'POST',
    headers: req.headers,
    body: JSON.stringify({ fortuneType, ...body }),
  })
  const mod = await import('@/app/api/fortune-access/check/route')
  return mod.POST(forwarded)
}

export async function tellerReviews(req: NextRequest) {
  const tellerId =
    req.nextUrl.searchParams.get('tellerId')?.trim() ??
    req.nextUrl.searchParams.get('id')?.trim() ??
    ''
  if (!tellerId) {
    return NextResponse.json({ error: 'tellerId gerekli' }, { status: 400 })
  }
  const mod = await import('@/app/api/fortune-tellers/[tellerId]/reviews/route')
  const fn = mod.GET as (
    r: NextRequest,
    c: { params: Promise<{ tellerId: string }> },
  ) => Promise<Response>
  return fn(req, { params: Promise.resolve({ tellerId }) })
}

export async function tournamentsJoin(req: NextRequest) {
  const body = await req.json().catch(() => ({}))
  const forwarded = new NextRequest(req.url, {
    method: 'POST',
    headers: req.headers,
    body: JSON.stringify(body),
  })
  const mod = await import('@/app/api/tournaments/route')
  if (typeof mod.POST === 'function') {
    return mod.POST(forwarded)
  }
  return NextResponse.json(
    { error: 'Turnuva katılımı şu an kullanılamıyor' },
    { status: 501 },
  )
}

export async function blogRecent(req: NextRequest) {
  const url = new URL(req.url)
  if (!url.searchParams.has('limit')) {
    url.searchParams.set('limit', '8')
  }
  const proxied = new NextRequest(url, { method: 'GET', headers: req.headers })
  const mod = await import('@/app/api/blog/route')
  return mod.GET(proxied)
}

export async function advisorsOnline(req: NextRequest) {
  const url = new URL(req.url)
  url.searchParams.set('online', '1')
  const proxied = new NextRequest(url, { method: 'GET', headers: req.headers })
  const mod = await import('@/app/api/fortune-tellers/route')
  return mod.GET(proxied)
}
