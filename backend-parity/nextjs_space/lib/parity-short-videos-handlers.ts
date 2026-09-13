import { NextRequest, NextResponse } from 'next/server'
import { authenticateRequest } from '@/lib/mobile-auth'
import prisma from '@/lib/db'

export async function shortVideosViewedMe(req: NextRequest) {
  const user = await authenticateRequest(req)
  if (!user) {
    return NextResponse.json({ error: 'Oturum gerekli' }, { status: 401 })
  }
  const limit = Math.min(
    50,
    Math.max(1, parseInt(req.nextUrl.searchParams.get('limit') || '20', 10) || 20),
  )
  const views = await prisma.shortVideoView.findMany({
    where: { userId: user.id },
    orderBy: { createdAt: 'desc' },
    take: limit,
    include: {
      video: {
        include: {
          user: { select: { id: true, name: true, username: true, image: true } },
          music: true,
        },
      },
    },
  })
  const videos = views.map((v) => v.video).filter(Boolean)
  return NextResponse.json({ success: true, videos, data: { videos } })
}

export async function shortVideosSubtitlesGenerate(
  req: NextRequest,
  videoId: string,
) {
  const user = await authenticateRequest(req)
  if (!user) {
    return NextResponse.json({ error: 'Oturum gerekli' }, { status: 401 })
  }
  const video = await prisma.shortVideo.findFirst({
    where: { id: videoId, userId: user.id },
    select: { id: true, description: true },
  })
  if (!video) {
    return NextResponse.json({ error: 'Video bulunamadı' }, { status: 404 })
  }
  await req.json().catch(() => ({}))
  return NextResponse.json({
    success: true,
    subtitles: '',
    subtitleText: '',
    srt: '',
    message: 'Altyazı üretimi henüz yapılandırılmadı',
  })
}

export async function callShortVideosExplore(
  req: NextRequest,
  pathname: string,
) {
  const mod = await import('@/app/api/short-videos/explore/route')
  const url = new URL(req.url)
  url.pathname = pathname
  const forwarded = new NextRequest(url, {
    method: req.method,
    headers: req.headers,
    body: req.body,
    duplex: 'half',
  } as RequestInit & { duplex?: 'half' })
  const fn = mod.GET as (r: NextRequest) => Promise<Response>
  return fn(forwarded)
}
