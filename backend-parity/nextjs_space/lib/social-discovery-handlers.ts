import { NextRequest, NextResponse } from 'next/server'

import { approximateDistancePayload, haversineKm } from '@/lib/social-distance'

async function tryPrisma() {
  try {
    const mod = await import('@/lib/db')
    return mod.default
  } catch {
    return null
  }
}

type LocUser = {
  id: string
  latitude: number | null
  longitude: number | null
  showDistance: boolean
  locationEnabled?: boolean | null
  hiddenFromDiscovery?: boolean
  discoveryPriority?: number
}

function userLoc(u: LocUser | null) {
  if (!u?.locationEnabled || u.latitude == null || u.longitude == null) return null
  return u
}

/** `GET /api/social/discovery` — keşif adayları + mesafe bandı (koordinat yok). */
export async function getSocialDiscovery(req: NextRequest) {
  try {
    const { requireAuth } = await import('@/lib/rbac')
    const auth = await requireAuth(req)
    if (auth instanceof NextResponse) return auth

    const prisma = await tryPrisma()
    if (!prisma) {
      return NextResponse.json({ success: true, users: [], items: [] })
    }

    const viewer = await prisma.user.findUnique({
      where: { id: auth.user.id },
      select: {
        id: true,
        latitude: true,
        longitude: true,
        showDistance: true,
        locationEnabled: true,
      },
    })

    const candidates = await prisma.user
      .findMany({
        where: {
          id: { not: auth.user.id },
          hiddenFromDiscovery: false,
          isBanned: false,
        },
        orderBy: [{ discoveryPriority: 'desc' }, { createdAt: 'desc' }],
        take: 40,
        select: {
          id: true,
          username: true,
          name: true,
          image: true,
          bio: true,
          latitude: true,
          longitude: true,
          showDistance: true,
          locationEnabled: true,
          isOnline: true,
        },
      })
      .catch(() => [])

    const vLoc = userLoc(viewer as LocUser)
    const users = candidates.map((c: LocUser & Record<string, unknown>) => {
      let distanceBand: string | undefined
      let distanceLabel: string | undefined
      if (vLoc && c.locationEnabled) {
        const clat = c.latitude
        const clon = c.longitude
        if (clat != null && clon != null) {
          const km = haversineKm(vLoc.latitude!, vLoc.longitude!, clat, clon)
          const payload = approximateDistancePayload(km, c.showDistance !== false)
          distanceBand = String(payload.distanceBand)
          distanceLabel = payload.distanceLabel
        }
      }
      return {
        id: c.id,
        userId: c.id,
        displayName: c.name ?? c.username ?? 'Kullanıcı',
        username: c.username,
        avatarUrl: c.image,
        distanceBand,
        distanceLabel,
        user: {
          id: c.id,
          username: c.username,
          displayName: c.name,
          avatarUrl: c.image,
          bio: c.bio,
          isOnline: c.isOnline,
        },
      }
    })

    return NextResponse.json({ success: true, users, items: users })
  } catch (e) {
    console.error('[social/discovery]', e)
    return NextResponse.json({ success: true, users: [], items: [] })
  }
}

/** `GET /api/social/actions` — son sosyal etkileşimler. */
export async function getSocialActions(req: NextRequest) {
  try {
    const { requireAuth } = await import('@/lib/rbac')
    const auth = await requireAuth(req)
    if (auth instanceof NextResponse) return auth

    const prisma = await tryPrisma()
    if (!prisma) {
      return NextResponse.json({ success: true, actions: [], items: [] })
    }

    const rows = await prisma.socialAction
      .findMany({
        where: { actorId: auth.user.id },
        orderBy: { createdAt: 'desc' },
        take: 50,
        include: {
          target: { select: { id: true, username: true, name: true, image: true } },
        },
      })
      .catch(() => [])

    const actions = rows.map((r: Record<string, unknown>) => ({
      id: r.id,
      type: r.type,
      action: r.type,
      targetId: r.targetId,
      createdAt: r.createdAt,
      target: r.target,
      user: r.target,
    }))

    return NextResponse.json({ success: true, actions, items: actions })
  } catch (e) {
    console.error('[social/actions]', e)
    return NextResponse.json({ success: true, actions: [], items: [] })
  }
}
