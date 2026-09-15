'use client'

/**
 * P6 iskelet — üretim web admin ile birleştirin.
 * Spec: docs/WEB_ADMIN_USER_COMMAND_CENTER_SPEC.md
 */
import { useEffect, useState } from 'react'

type Props = {
  userId: string
  open: boolean
  onClose: () => void
}

const TABS = [
  'Özet',
  'Aktivite',
  'Finans',
  'Ajans',
  'Moderasyon',
  'Yetkiler',
  'Raporlar',
] as const

export function UserCommandCenterModal({ userId, open, onClose }: Props) {
  const [tab, setTab] = useState<(typeof TABS)[number]>('Özet')
  const [overview, setOverview] = useState<Record<string, unknown> | null>(null)

  useEffect(() => {
    if (!open || !userId) return
    let cancelled = false
    fetch(`/api/admin/users/${encodeURIComponent(userId)}/overview`, {
      credentials: 'include',
    })
      .then((r) => r.json())
      .then((body) => {
        if (cancelled) return
        const data = body?.data ?? body
        setOverview(data && typeof data === 'object' ? data : null)
      })
      .catch(() => {
        if (!cancelled) setOverview(null)
      })
    return () => {
      cancelled = true
    }
  }, [open, userId])

  if (!open) return null

  return (
    <div
      role="dialog"
      aria-modal
      style={{
        position: 'fixed',
        inset: 0,
        background: 'rgba(0,0,0,0.55)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 9999,
      }}
      onClick={onClose}
    >
      <div
        style={{
          width: 'min(920px, 96vw)',
          maxHeight: '90vh',
          overflow: 'auto',
          background: '#0f1220',
          color: '#fff',
          borderRadius: 12,
          padding: 20,
        }}
        onClick={(e) => e.stopPropagation()}
      >
        <header style={{ display: 'flex', justifyContent: 'space-between' }}>
          <h2 style={{ margin: 0 }}>Kullanıcı merkezi</h2>
          <button type="button" onClick={onClose}>Kapat</button>
        </header>
        <p style={{ opacity: 0.7, fontSize: 13 }}>userId: {userId}</p>
        <nav style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 16 }}>
          {TABS.map((t) => (
            <button
              key={t}
              type="button"
              onClick={() => setTab(t)}
              style={{
                fontWeight: tab === t ? 700 : 400,
                background: tab === t ? '#3d2a7a' : 'transparent',
                color: '#fff',
                border: '1px solid #444',
                borderRadius: 8,
                padding: '6px 10px',
              }}
            >
              {t}
            </button>
          ))}
        </nav>
        <section>
          {tab === 'Özet' ? (
            <pre style={{ fontSize: 12, whiteSpace: 'pre-wrap' }}>
              {overview ? JSON.stringify(overview, null, 2) : 'Yükleniyor…'}
            </pre>
          ) : (
            <p style={{ opacity: 0.65 }}>
              Sekme «{tab}» — lazy fetch: GET /api/admin/users/{userId}/… (mobil parity ile aynı).
            </p>
          )}
        </section>
      </div>
    </div>
  )
}

export default UserCommandCenterModal
