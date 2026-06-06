'use client';

import { useCallback, useEffect, useState } from 'react';
import {
  fetchCredits,
  fetchJetonPackages,
  fetchPaymentConfig,
  fetchSessionUser,
  formatTry,
  submitJetonPaymentRequest,
  type JetonPackage,
  type PaymentConfig,
  type SessionUser,
} from '@/lib/jeton-api';

type Step = 'store' | 'methods' | 'whatsapp' | 'papara' | 'bank';

export default function JetonCheckout() {
  const [step, setStep] = useState<Step>('store');
  const [packages, setPackages] = useState<JetonPackage[]>([]);
  const [selected, setSelected] = useState<JetonPackage | null>(null);
  const [config, setConfig] = useState<PaymentConfig | null>(null);
  const [user, setUser] = useState<SessionUser | null>(null);
  const [balance, setBalance] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [pkgs, creds, u] = await Promise.all([
        fetchJetonPackages(),
        fetchCredits().catch(() => ({ jeton: 0 })),
        fetchSessionUser(),
      ]);
      setPackages(pkgs);
      setBalance(creds.jeton);
      setUser(u);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Yüklenemedi');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const openMethods = async (pkg: JetonPackage) => {
    setSelected(pkg);
    setError(null);
    try {
      const cfg = await fetchPaymentConfig();
      setConfig(cfg);
      const u = await fetchSessionUser();
      if (u) setUser(u);
      setStep('methods');
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Ödeme bilgileri alınamadı');
    }
  };

  const userLabel = user?.name || user?.username || 'Kullanıcı';
  const priceText = selected
    ? formatTry(selected.priceTry, selected.priceLabel)
    : '';

  const copy = async (text: string) => {
    try {
      await navigator.clipboard.writeText(text);
      alert('Kopyalandı');
    } catch {
      alert('Kopyalanamadı');
    }
  };

  const submit = async (method: string) => {
    if (!selected) return;
    setSubmitting(true);
    try {
      await submitJetonPaymentRequest({
        method,
        packageId: selected.id,
        packageTitle: selected.title,
        coins: selected.coins,
        priceTry: selected.priceTry,
      });
      alert('Talebiniz alındı. Onay sonrası jeton yüklenecek.');
      setStep('store');
      setSelected(null);
      load();
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Talep gönderilemedi');
    } finally {
      setSubmitting(false);
    }
  };

  const openWhatsApp = async () => {
    if (!selected || !config) return;
    await submit('whatsapp');
    const phone = config.whatsappNumber.replace(/\D/g, '');
    const msg = encodeURIComponent(
      `Merhaba, ${selected.title} (${selected.coins} jeton) satın almak istiyorum. Kullanıcı: ${userLabel}`,
    );
    window.open(`https://wa.me/${phone}?text=${msg}`, '_blank');
    setStep('store');
  };

  if (step !== 'store') {
    return (
      <div className="sheet-overlay" onClick={() => setStep('store')}>
        <div className="sheet" onClick={(e) => e.stopPropagation()}>
          {step === 'methods' && selected && (
            <>
              <header className="sheet-header">
                <div className="icon-box" style={{ background: 'rgba(255,213,79,.2)' }}>
                  💳
                </div>
                <div>
                  <h2>Ödeme Yöntemi</h2>
                  <span className="sub">Güvenli ödeme seçenekleri</span>
                </div>
                <button type="button" className="close-btn" onClick={() => setStep('store')}>
                  ×
                </button>
              </header>
              <div className="pkg-banner">
                <div className="coins">🪙</div>
                <div className="meta">{selected.title}</div>
                <div className="right">
                  <div className="price">{priceText}</div>
                  <div className="user">👤 {userLabel}</div>
                </div>
              </div>
              <p className="divider-label">Ödeme Yöntemleri</p>
              <button type="button" className="method-btn wa" onClick={() => setStep('whatsapp')}>
                <span>💬</span>
                <div>
                  <div className="title">
                    WhatsApp <span className="badge">Önerilen</span>
                  </div>
                  <div className="desc">Hızlı ve kolay ödeme</div>
                </div>
                <span>↗</span>
              </button>
              <button type="button" className="method-btn papara" onClick={() => setStep('papara')}>
                <span>👛</span>
                <div>
                  <div className="title">Papara</div>
                  <div className="desc">Papara ile ödeme</div>
                </div>
                <span>↗</span>
              </button>
              <button type="button" className="method-btn bank" onClick={() => setStep('bank')}>
                <span>🏦</span>
                <div>
                  <div className="title">Havale / IBAN</div>
                  <div className="desc">Banka havalesi ile ödeme</div>
                </div>
                <span>↗</span>
              </button>
              <div className="trust">
                <div>✓ Güvenli Ödeme</div>
                <div style={{ opacity: 0.75, fontSize: '0.75rem' }}>
                  Tüm işlemleriniz güvence altında
                </div>
              </div>
              <button type="button" className="btn-ghost" onClick={() => setStep('store')}>
                İptal
              </button>
            </>
          )}

          {step === 'whatsapp' && selected && (
            <>
              <header className="sheet-header">
                <div className="icon-box" style={{ background: 'rgba(37,211,102,.2)' }}>
                  💬
                </div>
                <div>
                  <h2>WhatsApp ile Ödeme</h2>
                </div>
                <button type="button" className="close-btn" onClick={() => setStep('store')}>
                  ×
                </button>
              </header>
              <div className="card">
                <div className="row">
                  <span className="label">Jeton Miktarı:</span>
                  <span className="val-yellow">{selected.coins}</span>
                </div>
                <div className="row">
                  <span className="label">Toplam:</span>
                  <span className="val-yellow">{priceText}</span>
                </div>
              </div>
              <div className="card" style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
                <div
                  style={{
                    width: 48,
                    height: 48,
                    borderRadius: '50%',
                    background: 'linear-gradient(135deg,#a855f7,#ec4899)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontWeight: 800,
                  }}
                >
                  {userLabel[0]?.toUpperCase()}
                </div>
                <div>
                  <strong>{userLabel}</strong>
                  <div style={{ fontSize: 12, color: 'var(--muted)' }}>{user?.email || '—'}</div>
                </div>
              </div>
              <p style={{ margin: '12px 16px', color: 'var(--muted)', fontSize: 14, lineHeight: 1.45 }}>
                Butona tıklayarak WhatsApp üzerinden sipariş verin. Mesaj otomatik hazırlanır.
              </p>
              <button
                type="button"
                className="btn-wa"
                disabled={submitting}
                onClick={openWhatsApp}
              >
                💬 WhatsApp&apos;tan Sipariş Ver
              </button>
              <button type="button" className="btn-ghost" onClick={() => setStep('methods')}>
                ← Geri Dön
              </button>
            </>
          )}

          {step === 'papara' && selected && config && (
            <>
              <header className="sheet-header">
                <div className="icon-box" style={{ background: 'rgba(168,85,247,.25)' }}>
                  👛
                </div>
                <div>
                  <h2>Papara ile Ödeme</h2>
                </div>
                <button type="button" className="close-btn" onClick={() => setStep('store')}>
                  ×
                </button>
              </header>
              <div className="card" style={{ display: 'flex', justifyContent: 'space-between' }}>
                <strong style={{ color: 'var(--yellow)' }}>{selected.title}</strong>
                <strong>{priceText}</strong>
              </div>
              <div className="card">
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <span className="label">Papara No:</span>
                  <button type="button" className="copy-link" onClick={() => copy(config.paparaAddress)}>
                    📋 Kopyala
                  </button>
                </div>
                <div style={{ fontWeight: 800, fontSize: '1.1rem', marginTop: 8 }}>
                  {config.paparaAddress || '—'}
                </div>
              </div>
              <div className="card row" style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span className="label">Alıcı:</span>
                <strong>{config.bankAccountHolder || '—'}</strong>
              </div>
              <div className="warn">
                <span>⚠</span>
                <span>
                  Açıklama kısmına kullanıcı adınızı yazın: <strong>&apos;{userLabel}&apos;</strong>
                </span>
              </div>
              <button
                type="button"
                className="btn-primary"
                disabled={submitting}
                onClick={() => submit('papara')}
              >
                Ödemeyi yaptım — talep gönder
              </button>
              <button type="button" className="btn-ghost" onClick={() => setStep('methods')}>
                ← Geri Dön
              </button>
            </>
          )}

          {step === 'bank' && selected && config && (
            <>
              <header className="sheet-header">
                <div className="icon-box" style={{ background: 'rgba(96,165,250,.25)' }}>
                  🏦
                </div>
                <div>
                  <h2>Banka Transferi</h2>
                </div>
                <button type="button" className="close-btn" onClick={() => setStep('store')}>
                  ×
                </button>
              </header>
              <div className="card" style={{ display: 'flex', justifyContent: 'space-between' }}>
                <strong style={{ color: 'var(--yellow)' }}>{selected.title}</strong>
                <strong>{priceText}</strong>
              </div>
              <div className="card">
                <div className="row">
                  <span className="label">Banka:</span>
                  <strong>{config.bankName || '—'}</strong>
                </div>
                <div className="row">
                  <span className="label">Alıcı:</span>
                  <strong>{config.bankAccountHolder || '—'}</strong>
                </div>
              </div>
              <div className="card">
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <span className="label">IBAN:</span>
                  <button type="button" className="copy-link" onClick={() => copy(config.bankIban)}>
                    📋 Kopyala
                  </button>
                </div>
                <div className="iban">{config.bankIban || '—'}</div>
              </div>
              <div className="warn">
                <span>⚠</span>
                <span>
                  Açıklama kısmına kullanıcı adınızı yazın: <strong>&apos;{userLabel}&apos;</strong>
                </span>
              </div>
              <button
                type="button"
                className="btn-primary"
                disabled={submitting}
                onClick={() => submit('bank_transfer')}
              >
                Ödemeyi yaptım — talep gönder
              </button>
              <button type="button" className="btn-ghost" onClick={() => setStep('methods')}>
                ← Geri Dön
              </button>
            </>
          )}
        </div>
      </div>
    );
  }

  return (
    <main className="store-page">
      <h1>Jeton yükle</h1>
      <p style={{ color: 'var(--muted)', fontSize: 14 }}>
        WhatsApp · Papara · Havale/EFT — mockup ile aynı akış
      </p>
      {balance != null && (
        <p style={{ marginTop: 12 }}>
          Mevcut jeton: <strong style={{ color: 'var(--yellow)' }}>{balance}</strong>
        </p>
      )}
      {error && <p style={{ color: '#f87171' }}>{error}</p>}
      {loading && <p>Yükleniyor…</p>}
      {!loading &&
        packages.map((p) => (
          <div key={p.id} className="pkg-list-item">
            <span>🪙</span>
            <div style={{ flex: 1 }}>
              <strong>{p.title}</strong>
              {p.badge && (
                <div style={{ fontSize: 12, color: 'var(--purple)' }}>{p.badge}</div>
              )}
              <div>{formatTry(p.priceTry, p.priceLabel)}</div>
            </div>
            <button type="button" onClick={() => openMethods(p)}>
              Satın al
            </button>
          </div>
        ))}
    </main>
  );
}
