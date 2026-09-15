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
          background: 'linear-gradient(145deg, #0B0F1E 0%, #15102B 100%)',
          color: '#fff',
          borderRadius: 16,
          border: '1px solid rgba(255,255,255,0.12)',
          boxShadow: '0 12px 40px rgba(0,0,0,0.45)',
          padding: 20,
        }}
        onClick={(e) => e.stopPropagation()}
      >
        <header style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <h2 style={{ margin: 0, fontWeight: 800 }}>Kullanıcı merkezi</h2>
            <p style={{ margin: '4px 0 0', fontSize: 12, color: 'rgba(255,255,255,0.55)' }}>
              {userId}
            </p>
          </div>
          <button
            type="button"
            onClick={onClose}
            style={{
              background: 'rgba(184,50,255,0.22)',
              border: '1px solid rgba(184,50,255,0.45)',
              color: '#fff',
              borderRadius: 10,
              padding: '8px 14px',
              cursor: 'pointer',
              fontWeight: 700,
            }}
          >
            Kapat
          </button>
        </header>
        <nav style={{ display: 'flex', gap: 8, flexWrap: 'wrap', margin: '16px 0' }}>
          {TABS.map((t) => (
            <button
              key={t}
              type="button"
              onClick={() => setTab(t)}
              style={{
                fontWeight: tab === t ? 800 : 500,
                background: tab === t ? 'rgba(184,50,255,0.28)' : 'rgba(255,255,255,0.06)',
                color: '#fff',
                border: tab === t
                  ? '1px solid rgba(184,50,255,0.55)'
                  : '1px solid rgba(255,255,255,0.12)',
                borderRadius: 10,
                padding: '6px 12px',
                cursor: 'pointer',
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
