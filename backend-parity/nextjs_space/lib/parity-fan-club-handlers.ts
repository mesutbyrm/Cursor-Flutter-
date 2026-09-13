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

export async function fanClubsPopular(req: NextRequest) {
  const limit = Math.min(
    50,
    Math.max(1, parseInt(req.nextUrl.searchParams.get('limit') || '20', 10) || 20),
  )
  const clubs = await prisma.fanClub.findMany({
    where: { isActive: true },
    orderBy: { memberCount: 'desc' },
    take: limit,
    include: {
      celebrity: {
        select: {
          id: true,
          name: true,
          slug: true,
          profileImage: true,
          category: true,
          isVerified: true,
          followerCount: true,
        },
      },
    },
  })
  return NextResponse.json({
    success: true,
    fanClubs: clubs,
    clubs,
    data: clubs,
    items: clubs,
  })
}

export async function fanClubJoin(req: NextRequest, fanClubId: string) {
  const gate = await requireUser(req)
  if (gate.res) return gate.res
  const club = await prisma.fanClub.findFirst({
    where: { id: fanClubId, isActive: true },
  })
  if (!club) {
    return NextResponse.json({ error: 'Fan kulübü bulunamadı' }, { status: 404 })
  }
  const existing = await prisma.fanClubMember.findUnique({
    where: { fanClubId_userId: { fanClubId, userId: gate.user!.id } },
  })
  if (existing) {
    return NextResponse.json({ success: true, joined: true, member: existing })
  }
  const member = await prisma.$transaction(async (tx) => {
    const m = await tx.fanClubMember.create({
      data: { fanClubId, userId: gate.user!.id },
    })
    await tx.fanClub.update({
      where: { id: fanClubId },
      data: { memberCount: { increment: 1 } },
    })
    return m
  })
  return NextResponse.json({ success: true, joined: true, member })
}

export async function fanClubPosts(req: NextRequest, fanClubId: string) {
  const club = await prisma.fanClub.findFirst({
    where: { id: fanClubId, isActive: true },
  })
  if (!club) {
    return NextResponse.json({ error: 'Fan kulübü bulunamadı' }, { status: 404 })
  }
  if (req.method === 'GET') {
    const limit = Math.min(
      50,
      Math.max(1, parseInt(req.nextUrl.searchParams.get('limit') || '30', 10) || 30),
    )
    const posts = await prisma.fanClubPost.findMany({
      where: { fanClubId },
      orderBy: [{ isPinned: 'desc' }, { createdAt: 'desc' }],
      take: limit,
      include: {
        user: { select: { id: true, name: true, username: true, image: true } },
      },
    })
    return NextResponse.json({ success: true, posts, data: { posts } })
  }
  const gate = await requireUser(req)
  if (gate.res) return gate.res
  const body = await req.json().catch(() => ({}))
  const content = String((body as { content?: string }).content || '').trim()
  if (!content) {
    return NextResponse.json({ error: 'İçerik gerekli' }, { status: 400 })
  }
  const post = await prisma.fanClubPost.create({
    data: {
      fanClubId,
      userId: gate.user!.id,
      content,
      image: (body as { image?: string }).image || null,
    },
    include: {
      user: { select: { id: true, name: true, username: true, image: true } },
    },
  })
  return NextResponse.json({ success: true, post })
}

export async function fanClubPolls(req: NextRequest, fanClubId: string) {
  const club = await prisma.fanClub.findFirst({
    where: { id: fanClubId, isActive: true },
  })
  if (!club) {
    return NextResponse.json({ error: 'Fan kulübü bulunamadı' }, { status: 404 })
  }
  if (req.method === 'GET') {
    const polls = await prisma.fanClubPoll.findMany({
      where: { fanClubId, isActive: true },
      orderBy: { createdAt: 'desc' },
      take: 30,
      include: {
        user: { select: { id: true, name: true, username: true, image: true } },
        votes: true,
      },
    })
    return NextResponse.json({ success: true, polls, data: { polls } })
  }
  const gate = await requireUser(req)
  if (gate.res) return gate.res
  const body = await req.json().catch(() => ({}))
  const question = String((body as { question?: string }).question || '').trim()
  const options = (body as { options?: unknown }).options
  if (!question || !Array.isArray(options) || options.length < 2) {
    return NextResponse.json({ error: 'Soru ve en az iki seçenek gerekli' }, { status: 400 })
  }
  const poll = await prisma.fanClubPoll.create({
    data: {
      fanClubId,
      userId: gate.user!.id,
      question,
      options,
    },
  })
  return NextResponse.json({ success: true, poll })
}
