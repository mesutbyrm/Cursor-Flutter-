import { NextRequest, NextResponse } from 'next/server'
import { authenticateRequest } from '@/lib/mobile-auth'
import prisma from '@/lib/db'

async function requireUser(req: NextRequest) {
  const user = await authenticateRequest(req)
  if (!user) {
    return { user: null, res: NextResponse.json({ error: 'Oturum gerekli' }, { status: 401 }) }
  }
  return { user, res: null as NextResponse | null }
}

export async function celebrityById(req: NextRequest, celebrityId: string) {
  const user = await authenticateRequest(req)
  const celebrity = await prisma.celebrity.findFirst({
    where: { id: celebrityId, isActive: true },
    include: {
      fanClub: { select: { id: true, memberCount: true, description: true } },
    },
  })
  if (!celebrity) {
    return NextResponse.json({ error: 'Ünlü bulunamadı' }, { status: 404 })
  }
  let isFollowing = false
  if (user) {
    const follow = await prisma.celebrityFollow.findUnique({
      where: { userId_celebrityId: { userId: user.id, celebrityId } },
    })
    isFollowing = !!follow
  }
  return NextResponse.json({
    success: true,
    celebrity,
    data: { ...celebrity, isFollowing },
    isFollowing,
  })
}

export async function celebrityFollow(req: NextRequest, celebrityId: string) {
  const gate = await requireUser(req)
  if (gate.res) return gate.res
  const celebrity = await prisma.celebrity.findFirst({
    where: { id: celebrityId, isActive: true },
  })
  if (!celebrity) {
    return NextResponse.json({ error: 'Ünlü bulunamadı' }, { status: 404 })
  }
  if (req.method === 'DELETE') {
    const deleted = await prisma.celebrityFollow.deleteMany({
      where: { userId: gate.user!.id, celebrityId },
    })
    if (deleted.count > 0) {
      await prisma.celebrity.update({
        where: { id: celebrityId },
        data: { followerCount: { decrement: 1 } },
      })
    }
    return NextResponse.json({ success: true, following: false })
  }
  const existing = await prisma.celebrityFollow.findUnique({
    where: { userId_celebrityId: { userId: gate.user!.id, celebrityId } },
  })
  if (existing) {
    return NextResponse.json({ success: true, following: true, follow: existing })
  }
  const follow = await prisma.$transaction(async (tx) => {
    const f = await tx.celebrityFollow.create({
      data: { userId: gate.user!.id, celebrityId },
    })
    await tx.celebrity.update({
      where: { id: celebrityId },
      data: { followerCount: { increment: 1 } },
    })
    return f
  })
  return NextResponse.json({ success: true, following: true, follow })
}

export async function celebrityPosts(req: NextRequest, celebrityId: string) {
  const celebrity = await prisma.celebrity.findFirst({
    where: { id: celebrityId, isActive: true },
  })
  if (!celebrity) {
    return NextResponse.json({ error: 'Ünlü bulunamadı' }, { status: 404 })
  }
  const limit = Math.min(
    50,
    Math.max(1, parseInt(req.nextUrl.searchParams.get('limit') || '30', 10) || 30),
  )
  const posts = await prisma.celebrityPost.findMany({
    where: { celebrityId, isActive: true },
    orderBy: [{ isPinned: 'desc' }, { createdAt: 'desc' }],
    take: limit,
  })
  return NextResponse.json({ success: true, posts, data: { posts } })
}
