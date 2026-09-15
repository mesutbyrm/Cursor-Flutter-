import { approximateDistancePayload, haversineKm } from '@/lib/social-distance'

type RoomRow = Record<string, unknown> & {
  ownerId?: string | null
  userId?: string | null
  createdBy?: string | null
  distanceBand?: string
  distanceLabel?: string
}

type LocUser = {
  latitude: number | null
  longitude: number | null
  showDistance: boolean
  locationEnabled?: boolean
}

function ownerIdOf(room: RoomRow): string | null {
  const id =
    room.ownerId ?? room.ownerUserId ?? room.hostUserId ?? room.createdBy ?? room.userId
  return id != null ? String(id).trim() : null
}

/**
 * Üretim `GET /api/chat/rooms` yanıtına viewer mesafe bandı ekler — koordinat gönderilmez.
 */
export function enrichVoiceRoomsWithDistance(
  rooms: RoomRow[],
  viewer: LocUser | null,
  ownerLocations: Map<string, LocUser>,
): RoomRow[] {
  if (!viewer?.locationEnabled || viewer.latitude == null || viewer.longitude == null) {
    return rooms
  }
  return rooms.map((room) => {
    const oid = ownerIdOf(room)
    if (!oid) return room
    const owner = ownerLocations.get(oid)
    if (!owner?.locationEnabled || owner.latitude == null || owner.longitude == null) {
      return room
    }
    const km = haversineKm(
      viewer.latitude!,
      viewer.longitude!,
      owner.latitude!,
      owner.longitude!,
    )
    const payload = approximateDistancePayload(km, owner.showDistance)
    return {
      ...room,
      distanceBand: payload.distanceBand,
      distanceLabel: payload.distanceLabel,
    }
  })
}
