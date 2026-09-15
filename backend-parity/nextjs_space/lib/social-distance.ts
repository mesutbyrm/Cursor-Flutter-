/**
 * Sunucu tarafı yaklaşık mesafe — koordinat istemciye gönderilmez (§26–28).
 */

export type DistanceBandKey =
  | '0_1'
  | '1_5'
  | '5_10'
  | '10_25'
  | '25_50'
  | '50_plus'

export function kmToDistanceBand(km: number): DistanceBandKey {
  if (km < 1) return '0_1'
  if (km < 5) return '1_5'
  if (km < 10) return '5_10'
  if (km < 25) return '10_25'
  if (km < 50) return '25_50'
  return '50_plus'
}

const LABELS: Record<DistanceBandKey, string> = {
  '0_1': 'Yaklaşık 1 km uzakta',
  '1_5': 'Yaklaşık 1–5 km uzakta',
  '5_10': 'Yaklaşık 5–10 km uzakta',
  '10_25': 'Yaklaşık 10–25 km uzakta',
  '25_50': 'Yaklaşık 25–50 km uzakta',
  '50_plus': '50+ km uzakta',
}

export function bandDisplayLabel(band: DistanceBandKey): string {
  return LABELS[band]
}

/** Haversine km — yalnızca sunucu içi; yanıtta distanceKm göndermeyin. */
export function haversineKm(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number,
): number {
  const R = 6371
  const dLat = ((lat2 - lat1) * Math.PI) / 180
  const dLon = ((lon2 - lon1) * Math.PI) / 180
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) ** 2
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
}

export function approximateDistancePayload(
  km: number,
  showDistance: boolean,
): { distanceBand: DistanceBandKey | 'hidden'; distanceLabel: string } {
  if (!showDistance) {
    return { distanceBand: 'hidden', distanceLabel: 'Mesafe bilgisi gizli' }
  }
  const band = kmToDistanceBand(km)
  return { distanceBand: band, distanceLabel: bandDisplayLabel(band) }
}
