import { NextRequest, NextResponse } from 'next/server'

import { enrichVoiceRoomsWithDistance } from '@/lib/voice-room-distance-enrich'

async function tryPrisma() {
  try {
    const mod = await import('@/lib/db')
    return mod.default
  } catch {
    return null
  }
}

/** `GET /api/chat/rooms` — liste + mesafe bandı (viewer konumuna göre). */
export async function getChatRoomsList(req: NextRequest) {
  try {
    const { requireAuth } = await import('@/lib/rbac')
    const auth = await requireAuth(req)
    if (auth instanceof NextResponse) return auth

    const prisma = await tryPrisma()
    if (!prisma) {
      return NextResponse.json({ success: true, rooms: [], items: [] })
    }

    const viewer = await prisma.user.findUnique({
      where: { id: auth.user.id },
      select: {
        latitude: true,
        longitude: true,
        showDistance: true,
        locationEnabled: true,
      },
    })

    const rooms = await prisma.chatRoom
      .findMany({
        where: { isActive: true },
        orderBy: { updatedAt: 'desc' },
        take: 80,
        include: {
          owner: {
            select: {
              id: true,
              name: true,
              username: true,
              image: true,
              latitude: true,
              longitude: true,
              showDistance: true,
              locationEnabled: true,
            },
          },
        },
      })
      .catch(() => [])

    const ownerIds = new Set<string>()
    const mapped = rooms.map((r: Record<string, unknown>) => {
      const owner = r.owner as Record<string, unknown> | null
      const ownerId = (r.ownerId ?? owner?.id) as string | undefined
      if (ownerId) ownerIds.add(ownerId)
      return {
        id: r.id,
        slug: r.slug,
        nameTr: r.nameTr,
        descTr: r.descTr,
        ownerId,
        ownerName: owner?.name ?? owner?.username,
        ownerAvatarUrl: owner?.image,
        onlineCount: 0,
        userCount: 0,
      }
    })

    const locMap = new Map<string, {
      latitude: number | null
      longitude: number | null
      showDistance: boolean
      locationEnabled?: boolean
    }>()
    for (const room of rooms) {
      const owner = (room as { owner?: Record<string, unknown> }).owner
      if (owner?.id) {
        locMap.set(String(owner.id), {
          latitude: owner.latitude as number | null,
          longitude: owner.longitude as number | null,
          showDistance: owner.showDistance !== false,
          locationEnabled: owner.locationEnabled !== false,
        })
      }
    }

    const enriched = enrichVoiceRoomsWithDistance(
      mapped,
      viewer
        ? {
            latitude: viewer.latitude,
            longitude: viewer.longitude,
            showDistance: viewer.showDistance !== false,
            locationEnabled: viewer.locationEnabled !== false,
          }
        : null,
      locMap,
    )

    return NextResponse.json({ success: true, rooms: enriched, items: enriched })
  } catch (e) {
    console.error('[chat/rooms GET]', e)
    return NextResponse.json({ success: true, rooms: [], items: [] })
  }
}
