# Release Gate Closure — 1.0.371+409


> **Güncel (2026-09-07):** **`1.0.371+409`** · Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

**Tarih:** 2026-09-07  
**Dal:** `main`  
**Son APK run:** [34146919509](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/34146919509) — **FINAL: PASS**

## Otomatik kapılar

| Kapı | Sonuç | Detay |
|------|-------|-------|
| `dart analyze` | ✅ PASS | 0 error |
| `flutter test` | ✅ PASS | 1081 geçti, 2 skip (CI run `34144153254`) |
| Release gate 1–9 | ✅ PASS | Build + signing + artifact |
| apk-latest upload | ✅ PASS | 502 dayanıklılığı (`814f8758`) |
| apk-latest metadata | ✅ PASS | Ayrı adım; title `Canlifal APK 1.0.371+409` |
| APK HTTP | ✅ 200 | İndirme + aapt metadata doğrulama |
| APK versionName | ✅ 1.0.371 | universal APK |
| APK versionCode | ✅ 409 | pubspec build number |

## Faz 1 + Faz 2 (mobil — main)

| Faz | Özet | Commit serisi |
|-----|------|----------------|
| Faz 1 | SSE tek kanal, oda SoT, Socket.IO kapalı | `28c89fb3` |
| Faz 2 | Psychic TRTC 5 sn freeze — token-only join, alias drift fix | `f8d83e84` |
| CI fix | Release 502, docs push detached HEAD / kirli ağaç | `814f8758`, `bf205d3a` |

## Açık — manuel (testler en son)

| ID | Madde | Durum |
|----|-------|-------|
| P0-j | Danışan jeton (admin top-up) | ✅ **~100000** jeton (2026-09-07) |
| API otomasyon | M5 smoke + M7 song-request | ✅ PASS=6, HTTP 200 |
| Falcı probe | Host falcı listesinde | ✅ `Cursor Host Test` (9 falcı) |
| API Gate 3 (acceptance) | Session + TRTC | ✅ PASS (host listede) |
| P0 | Psychic TRTC 2-cihaz kabul (T+5s freeze) | **OPEN** — kullanıcı testi **sonra** |
| P1 | Voice/gift/PK/müzik 2-cihaz checklist | Bekliyor (P0 sonrası) |
| P2 | `bana_ozel_hub_section_test` overflow | ✅ Düzeltildi (CHANGELOG); CI 1081 pass — bloker değil |

**RELEASE READY:** `NO` — otomatik kapılar PASS; Psychic P0 kabul kullanıcı testine bağlı.

Agent kapalı özeti: [`AGENT_CLOSED.md`](AGENT_CLOSED.md)

## APK

- **İndir:** https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk
- **Detay:** `docs/LATEST_APK_BUILD.md`
- **Checklist:** `docs/RELEASE_CHECKLIST.md`
