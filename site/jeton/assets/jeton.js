(function () {
  const API_BASE =
    document.querySelector('meta[name="api-base"]')?.content ||
    window.CANLIFAL_API_BASE ||
    '';

  const state = {
    packages: [],
    config: null,
    user: null,
    selected: null,
    method: null,
  };

  const $ = (sel) => document.querySelector(sel);
  const views = {
    store: '#view-store',
    methods: '#view-methods',
    whatsapp: '#view-whatsapp',
    papara: '#view-papara',
    bank: '#view-bank',
  };

  function showView(name) {
    document.querySelectorAll('.view').forEach((el) => el.classList.remove('active'));
    const v = document.querySelector(views[name]);
    if (v) v.classList.add('active');
    window.location.hash = name;
  }

  function toast(msg) {
    const t = $('#toast');
    if (!t) return;
    t.textContent = msg;
    t.classList.add('show');
    setTimeout(() => t.classList.remove('show'), 2800);
  }

  async function api(path, options = {}) {
    const url = `${API_BASE.replace(/\/$/, '')}${path}`;
    const res = await fetch(url, {
      credentials: 'include',
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
        ...(options.headers || {}),
      },
      ...options,
    });
    const data = await res.json().catch(() => ({}));
    if (!res.ok) {
      const err = data.error || data.message || `HTTP ${res.status}`;
      throw new Error(err);
    }
    return data.data != null && data.success === true ? data.data : data;
  }

  function formatPrice(pkg) {
    if (pkg.priceLabel) return pkg.priceLabel;
    if (pkg.priceTry != null) {
      return new Intl.NumberFormat('tr-TR', {
        style: 'currency',
        currency: 'TRY',
      }).format(pkg.priceTry);
    }
    return '—';
  }

  function usernameLabel() {
    if (!state.user) return 'Kullanıcı';
    return (
      state.user.displayName ||
      state.user.username ||
      state.user.name ||
      state.user.email?.split('@')[0] ||
      'Kullanıcı'
    );
  }

  function fillPackageSummary() {
    const p = state.selected;
    if (!p) return;
    const title = p.title || `${p.coins} Jeton`;
    const price = formatPrice(p);
    document.querySelectorAll('[data-pkg-title]').forEach((el) => {
      el.textContent = title;
    });
    document.querySelectorAll('[data-pkg-price]').forEach((el) => {
      el.textContent = price;
    });
    document.querySelectorAll('[data-pkg-coins]').forEach((el) => {
      el.textContent = String(p.coins);
    });
    document.querySelectorAll('[data-username]').forEach((el) => {
      el.textContent = `'${usernameLabel()}'`;
    });
    const tag = $('#methods-user-tag');
    if (tag) tag.textContent = usernameLabel();
  }

  function fillUserCard() {
    const name = $('#wa-user-name');
    const email = $('#wa-user-email');
    const av = $('#wa-user-avatar');
    if (name) name.textContent = usernameLabel();
    if (email) email.textContent = state.user?.email || '—';
    if (av) av.textContent = (usernameLabel()[0] || '?').toUpperCase();
  }

  function fillPaymentDetails() {
    const cfg = state.config || {};
    const papara = cfg.paparaAddress || cfg.papara || '—';
    const iban = cfg.bankIban || cfg.iban || '—';
    const bank = cfg.bankName || '—';
    const holder = cfg.bankAccountHolder || cfg.accountHolder || '—';
    const wa = cfg.whatsappNumber || cfg.whatsapp || '—';

    const paparaEl = $('#papara-no');
    if (paparaEl) paparaEl.textContent = papara;
    const ibanEl = $('#bank-iban');
    if (ibanEl) ibanEl.textContent = iban;
    const bankEl = $('#bank-name');
    if (bankEl) bankEl.textContent = bank;
    const holderEl = $('#bank-holder');
    if (holderEl) holderEl.textContent = holder;
    const holder2 = $('#papara-holder');
    if (holder2) holder2.textContent = holder;

    state._waPhone = wa.replace(/\D/g, '');
    state._papara = papara;
    state._iban = iban;
  }

  async function loadStore() {
    const list = $('#packages-list');
    const bal = $('#balance-jeton');
    try {
      const [credits, jetonRes] = await Promise.all([
        api('/api/user/credits').catch(() => null),
        api('/api/jeton'),
      ]);
      if (credits) {
        state.user = state.user || {};
        state.user.role = credits.role;
        const j = credits.jetonBalance ?? credits.jeton ?? credits.coins ?? 0;
        if (bal) bal.textContent = String(j);
      }
      const raw = jetonRes.packages || jetonRes.items || jetonRes.data || jetonRes;
      state.packages = Array.isArray(raw) ? raw : [];
      if (!list) return;
      if (state.packages.length === 0) {
        list.innerHTML = '<p class="error-box">Paket bulunamadı.</p>';
        return;
      }
      list.innerHTML = state.packages
        .map((p) => {
          const id = p.id || p.packageId || '';
          const coins = p.coins ?? p.amount ?? 0;
          const title = p.title || `${coins} Jeton`;
          const price = formatPrice(p);
          return `<article class="pkg-card" data-id="${id}">
            <div class="coin-icon">🪙</div>
            <div>
              <strong>${title}</strong>
              ${p.badge ? `<div style="font-size:12px;color:#c4b5fd">${p.badge}</div>` : ''}
              <div style="margin-top:4px;font-weight:800">${price}</div>
            </div>
            <button type="button" class="buy" data-buy="${id}">Satın al</button>
          </article>`;
        })
        .join('');
      list.querySelectorAll('[data-buy]').forEach((btn) => {
        btn.addEventListener('click', (e) => {
          e.stopPropagation();
          const id = btn.getAttribute('data-buy');
          state.selected = state.packages.find((x) => (x.id || x.packageId) === id);
          openMethods();
        });
      });
    } catch (e) {
      if (list) list.innerHTML = `<p class="error-box">${e.message}<br><small>Oturum açın veya API_BASE ayarlayın.</small></p>`;
    }
  }

  async function openMethods() {
    try {
      state.config = await api('/api/payment/config');
      const session = await api('/api/auth/session').catch(() => null);
      if (session?.user) {
        state.user = { ...state.user, ...session.user };
      }
      const prof = await api('/api/user/profile').catch(() => null);
      if (prof) state.user = { ...state.user, ...prof };
    } catch (e) {
      toast(e.message);
      return;
    }
    fillPackageSummary();
    fillUserCard();
    fillPaymentDetails();
    showView('methods');
  }

  function waMessage() {
    const p = state.selected;
    return encodeURIComponent(
      `Merhaba, ${p?.title || p?.coins + ' Jeton'} (${p?.coins} jeton) satın almak istiyorum. ` +
        `Kullanıcı: ${usernameLabel()} · Açıklama: ${usernameLabel()}`
    );
  }

  async function submitRequest(method, extraNotes) {
    const p = state.selected;
    if (!p) return;
    try {
      await api('/api/payment/requests', {
        method: 'POST',
        body: JSON.stringify({
          requestType: 'jeton',
          method,
          packageId: p.id || p.packageId,
          packageTitle: p.title || `${p.coins} Jeton`,
          coins: p.coins,
          priceTry: p.priceTry,
          notes: extraNotes || `Jeton yükleme · ${method}`,
        }),
      });
      toast('Talebiniz alındı. Onay sonrası jeton yüklenir.');
    } catch (e) {
      toast(e.message);
      throw e;
    }
  }

  function bind() {
    $('#btn-close-methods')?.addEventListener('click', () => showView('store'));
    $('#btn-cancel-methods')?.addEventListener('click', () => showView('store'));

    $('#btn-method-wa')?.addEventListener('click', () => {
      state.method = 'whatsapp';
      fillPackageSummary();
      fillUserCard();
      showView('whatsapp');
    });
    $('#btn-method-papara')?.addEventListener('click', () => {
      state.method = 'papara';
      fillPackageSummary();
      fillPaymentDetails();
      showView('papara');
    });
    $('#btn-method-bank')?.addEventListener('click', () => {
      state.method = 'bank_transfer';
      fillPackageSummary();
      fillPaymentDetails();
      showView('bank');
    });

    document.querySelectorAll('[data-back]').forEach((el) => {
      el.addEventListener('click', () => showView('methods'));
    });
    document.querySelectorAll('[data-back-store]').forEach((el) => {
      el.addEventListener('click', () => showView('store'));
    });

    $('#btn-wa-order')?.addEventListener('click', async () => {
      const phone = state._waPhone;
      if (!phone) {
        toast('WhatsApp numarası ayarlanmamış');
        return;
      }
      try {
        await submitRequest('whatsapp');
        window.open(`https://wa.me/${phone}?text=${waMessage()}`, '_blank');
      } catch (_) {}
    });

    $('#btn-papara-done')?.addEventListener('click', async () => {
      try {
        await submitRequest('papara');
        showView('store');
      } catch (_) {}
    });

    $('#btn-bank-done')?.addEventListener('click', async () => {
      try {
        await submitRequest('bank_transfer');
        showView('store');
      } catch (_) {}
    });

    document.querySelectorAll('[data-copy]').forEach((btn) => {
      btn.addEventListener('click', async () => {
        const key = btn.getAttribute('data-copy');
        const text =
          key === 'iban' ? state._iban : key === 'papara' ? state._papara : '';
        try {
          await navigator.clipboard.writeText(text);
          toast('Kopyalandı');
        } catch {
          toast('Kopyalanamadı');
        }
      });
    });
  }

  function init() {
    bind();
    const hash = (window.location.hash || '#store').replace('#', '');
    if (views[hash]) showView(hash);
    else showView('store');
    loadStore();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
