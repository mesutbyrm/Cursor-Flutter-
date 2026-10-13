import prisma from '@/lib/db'

/** Mobil `kSocialPlatforms` ile aynı sıra. */
export const SOCIAL_PLATFORMS = [
  { id: 'instagram', label: 'Instagram' },
  { id: 'tiktok', label: 'TikTok' },
  { id: 'youtube', label: 'YouTube' },
  { id: 'x', label: 'X (Twitter)' },
  { id: 'facebook', label: 'Facebook' },
  { id: 'telegram', label: 'Telegram' },
  { id: 'whatsapp', label: 'WhatsApp' },
  { id: 'website', label: 'Web sitesi' },
] as const

const SETTING_KEY = 'site.social_accounts_v1'

export type StoredSocialAccount = {
  platform: string
  value: string
  enabled: boolean
}

export type PublicSocialAccount = {
  platform: string
  label: string
  value: string
  handle?: string
  url: string
  enabled: boolean
}

function stripAt(v: string): string {
  return v.trim().replace(/^@+/, '')
}

/** Kullanıcı adı veya tam URL → güvenli https bağlantısı. */
export function socialAccountUrl(platform: string, raw: string): string {
  const v = raw.trim()
  if (!v) return ''
  if (/^https?:\/\//i.test(v)) return v
  const handle = stripAt(v)
  switch (platform) {
    case 'instagram':
      return `https://instagram.com/${handle}`
    case 'tiktok':
      return `https://www.tiktok.com/@${handle}`
    case 'youtube':
      return handle.startsWith('UC') || handle.includes('/')
        ? `https://www.youtube.com/${handle}`
        : `https://www.youtube.com/@${handle}`
    case 'x':
      return `https://x.com/${handle}`
    case 'facebook':
      return `https://facebook.com/${handle}`
    case 'telegram':
      return handle.startsWith('+') ? `https://t.me/${handle.slice(1)}` : `https://t.me/${handle}`
    case 'whatsapp':
      return `https://wa.me/${handle.replace(/\D/g, '')}`
    case 'website':
      return handle.includes('.') ? (handle.startsWith('http') ? handle : `https://${handle}`) : ''
    default:
      return ''
  }
}

async function readStored(): Promise<StoredSocialAccount[]> {
  const row = await prisma.siteSetting.findUnique({ where: { key: SETTING_KEY } })
  if (!row?.value) return []
  try {
    const parsed = JSON.parse(row.value)
    if (!Array.isArray(parsed)) return []
    return parsed
      .filter((x) => x && typeof x.platform === 'string')
      .map((x) => ({
        platform: String(x.platform),
        value: String(x.value ?? x.handle ?? ''),
        enabled: x.enabled !== false,
      }))
  } catch {
    return []
  }
}

export async function loadSocialAccounts(): Promise<PublicSocialAccount[]> {
  const stored = await readStored()
  const byPlatform = new Map(stored.map((s) => [s.platform, s]))
  return SOCIAL_PLATFORMS.map(({ id, label }) => {
    const s = byPlatform.get(id)
    const value = s?.value?.trim() ?? ''
    const enabled = s?.enabled !== false && value.length > 0
    const url = value ? socialAccountUrl(id, value) : ''
    return {
      platform: id,
      label,
      value,
      handle: value ? stripAt(value) : undefined,
      url,
      enabled,
    }
  })
}

export async function saveSocialAccounts(
  rows: Array<{ platform: string; value?: string; enabled?: boolean }>,
): Promise<PublicSocialAccount[]> {
  const byPlatform = new Map<string, StoredSocialAccount>()
  for (const r of rows) {
    const platform = String(r.platform || '').trim()
    if (!platform) continue
    const value = String(r.value ?? '').trim()
    const enabled = r.enabled !== false
    if (!value) {
      byPlatform.set(platform, { platform, value: '', enabled: false })
    } else {
      byPlatform.set(platform, { platform, value, enabled })
    }
  }
  const merged: StoredSocialAccount[] = SOCIAL_PLATFORMS.map(({ id }) => {
    const s = byPlatform.get(id)
    return s ?? { platform: id, value: '', enabled: false }
  })
  await prisma.siteSetting.upsert({
    where: { key: SETTING_KEY },
    create: { key: SETTING_KEY, value: JSON.stringify(merged) },
    update: { value: JSON.stringify(merged) },
  })
  return loadSocialAccounts()
}
