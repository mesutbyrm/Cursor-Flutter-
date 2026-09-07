# Canlifal — Release Checklist


> **Güncel (2026-09-07):** **`1.0.371+409`** · Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

Sürüm: **1.0.371+409**  
Tarih: **2026-09-07**  
Dal: `main`  
Son release gate: [Run 34146919509](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/34146919509) — **FINAL: PASS**

## Otomatik CI

| Kontrol | Durum | Not |
|---------|-------|-----|
| `dart analyze` | ✅ PASS | 0 error (release gate) |
| `flutter test` | ✅ PASS | 1081 geçti, 2 skip (run `34144153254`) |
| `flutter build apk --release` | ✅ PASS | Gate 9 — versionName 1.0.371, versionCode 409 |
| apk-latest upload | ✅ PASS | 502 dayanıklılığı (`814f8758`) |
| APK HTTP + metadata | ✅ PASS | HTTP 200, aapt doğrulama |

## Fonksiyonel checklist

| Alan | Durum | Not |
|------|-------|-----|
| Auth | ✅ | JWT refresh, logout SSE teardown |
| Home | ✅ | Lazy section load, paralel bootstrap |
| Live / Voice (Faz 1) | ✅ kod | SSE SoT, Socket.IO kapalı; 2-cihaz manuel |
| **Psychic TRTC (Faz 2)** | ⚠️ **P0 OPEN** | 5 sn freeze fix kodda; **2-cihaz kabul bekleniyor** |
| Tencent RTC | ✅ fix | Tek `TrtcRoomManager`, gate + psychic token yolu |
| Participant / Seat | ⚠️ | Backend canonical; manuel test |
| Heartbeat | ✅ | Psychic live heartbeat kaldırıldı; presence SSE |
| Gift | ✅ | SSE + canonical refresh |
| PK | ⚠️ | SSE; 4s poll overlap (P2) |
| Music | ✅ | Leave → player stop + SSE release |
| Social / Shorts / Stories | ✅ / ⚠️ | Shorts 50 swipe memory — cihazda |
| Fortune | ✅ | SSE streaming ayrı |
| Wallet / Profile / Messages / Notifications / Games | ✅ | |
| Logout | ✅ | SSE hub dispose + provider invalidation |

## Multi-device (manuel — production öncesi)

### P0 — Psychic TRTC (öncelik)

APK: https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk

**Önkoşul:** `bash scripts/p0-go.sh`

- [x] Jeton OK (~98k) + falcı probe ✅ (`cursor.host.*` listede)
- [ ] T0–T+60s: çift yönlü A/V, **T+5s donma yok**
- [ ] WiFi ↔ mobil data — kontrollü reconnect
- [ ] Oturum A→B→A — duplicate stream yok
- [ ] Arka plan / ön plan — gereksiz rejoin yok

Detay: `docs/LIVE_PSYCHICS_REMAINING.md` § P0 freeze kabul

### P1 — Genel platform

- [ ] Device A + B voice room join/leave/rejoin
- [ ] Seat sync owner/viewer
- [ ] Gift amount + wallet + ranking
- [ ] PK request/accept/score
- [ ] Music room switch (eski şarkı durur)
- [ ] DM + notification unread
- [ ] User A logout → User B login (cache isolation)

## Release gate

**RELEASE READY: NO** — Otomatik kapılar PASS; **Psychic P0 + P1 cihaz kabul** gerekir.

Kullanıcı test akışı:

```bash
bash scripts/kalan-isler.sh                  # tüm kalan işler özeti
bash scripts/p0-go.sh
bash scripts/user-test-start.sh p0
bash scripts/on-p0-pass.sh
bash scripts/p1-go.sh
bash scripts/on-p1-pass.sh
bash scripts/p2-go.sh
bash scripts/on-release-ready-candidate.sh
```

P0+P1 PASS bildirildikten sonra agent `RELEASE READY: YES` işaretleyebilir.

Hızlı referans: [`USER_TEST_QUICK_REF.md`](USER_TEST_QUICK_REF.md)
