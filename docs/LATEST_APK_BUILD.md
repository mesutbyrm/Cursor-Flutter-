# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.738+791` |
| Tarih (UTC) | 2026-10-07 20:05 |
| Commit | [`a4a8dd9abf1c9f0a97e25b5aeeda85c17af54093`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/a4a8dd9abf1c9f0a97e25b5aeeda85c17af54093) |
| İş akışı | [Run 37676615501](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37676615501) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.738+791 (2026-10-07) — Oyun lobisi düzeltmesi + masaya katılma

- **Oyun lobisi (hata):** «Masalar» ve «Son kazananlar» sekmeleri backend'de olmayan bölüm adlarını istiyordu (`tables`, `winners` → canlıda «Geçersiz section»). Doğru adlar: `live_tables`, `recent_winners`
- **Masaya katıl / izle:** lobideki masaya dokununca bekleyen masaya katılır (`POST /api/games/room/{id}` veya SOS için `POST /api/games/sos/{id}`), aktif masa izlenir; web'de açılan masalara mobilden girilebilir
- **SOS:** «Otomatik eşleş» düğmesi SOS'ta gizlendi (`/api/games/auto-match` SOS'u kabul etmiyor)
- Gerçek cihaz: **BLOCKED**


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
