export type JetonPackage = {
  id: string;
  title: string;
  coins: number;
  priceTry?: number;
  priceLabel?: string;
  badge?: string;
};

export type PaymentConfig = {
  whatsappNumber: string;
  paparaAddress: string;
  bankName: string;
  bankIban: string;
  bankAccountHolder: string;
};

export type SessionUser = {
  name: string;
  email: string;
  username: string;
};

const base = () =>
  process.env.NEXT_PUBLIC_SITE_URL?.replace(/\/$/, '') || 'https://canlifal.com';

async function api<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(`${base()}${path}`, {
    ...init,
    credentials: 'include',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      ...(init?.headers || {}),
    },
    cache: 'no-store',
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    const err = (data as { error?: string }).error || `HTTP ${res.status}`;
    throw new Error(err);
  }
  const wrapped = data as { success?: boolean; data?: T };
  if (wrapped.success === true && wrapped.data != null) return wrapped.data;
  return data as T;
}

export async function fetchJetonPackages(): Promise<JetonPackage[]> {
  const data = await api<{ packages?: JetonPackage[]; items?: JetonPackage[] }>(
    '/api/jeton',
  );
  const list = data.packages || data.items || (Array.isArray(data) ? data : []);
  return list.map((p) => ({
    id: p.id || String(p.coins),
    title: p.title || `${p.coins} Jeton`,
    coins: p.coins,
    priceTry: p.priceTry,
    priceLabel: p.priceLabel,
    badge: p.badge,
  }));
}

export async function fetchPaymentConfig(): Promise<PaymentConfig> {
  return api<PaymentConfig>('/api/payment/config');
}

export async function fetchCredits(): Promise<{ jeton: number }> {
  const c = await api<{
    jetonBalance?: number;
    jeton?: number;
    coins?: number;
  }>('/api/user/credits');
  return { jeton: c.jetonBalance ?? c.jeton ?? c.coins ?? 0 };
}

export async function fetchSessionUser(): Promise<SessionUser | null> {
  try {
    const s = await api<{ user?: SessionUser }>('/api/auth/session');
    if (s.user) return s.user;
  } catch {
    /* ignore */
  }
  try {
    const p = await api<SessionUser & { displayName?: string }>('/api/user/profile');
    return {
      name: p.displayName || p.name || p.username || 'Kullanıcı',
      email: p.email || '',
      username: p.username || p.name || 'kullanici',
    };
  } catch {
    return null;
  }
}

export async function submitJetonPaymentRequest(body: {
  method: string;
  packageId: string;
  packageTitle: string;
  coins: number;
  priceTry?: number;
}) {
  return api('/api/payment/requests', {
    method: 'POST',
    body: JSON.stringify({
      requestType: 'jeton',
      ...body,
      notes: `Jeton yükleme · ${body.method}`,
    }),
  });
}

export function formatTry(priceTry?: number, priceLabel?: string) {
  if (priceLabel?.trim()) return priceLabel.trim();
  if (priceTry == null) return '—';
  return new Intl.NumberFormat('tr-TR', {
    style: 'currency',
    currency: 'TRY',
  }).format(priceTry);
}
