# CanliFal — Test Results

**Date:** 2026-08-04  
**App version:** `1.0.125+159`  
**Branch:** `cursor/room-music-system-df6c`

---

## Özet

| Suite | Sonuç | Detay |
|-------|-------|-------|
| **Flutter unit/widget** | ✅ **370 passed**, 2 skipped | `flutter test` |
| **Dart analyze (ERROR gate)** | ✅ **0 ERROR** | 111 WARNING, 157 INFO |
| **API mirror tests** | ✅ Pass | `npm test` (tsx node:test) |
| **Acceptance tests (20 madde)** | ⚠️ Çalıştırılmadı | `scripts/run-acceptance-tests.sh` |
| **E2E / integration** | ⚠️ Yok | Emülatör CI'da yok |
| **1000 kullanıcı senkron** | ⚠️ Yok | Load test yapılmadı |
| **Release APK smoke** | ❌ APK derlenmedi | Kullanıcı talimatı |

**%100 başarı hedefi:** ❌ Karşılanmadı (E2E, acceptance, load test eksik)

---

## Flutter test (`flutter test`)

```
Son çalıştırma: 370 passed, 2 skipped, 0 failed
Süre: ~37s
```

### Önemli test grupları

| Dosya | Konu |
|-------|------|
| `test/room_song_bloc_test.dart` | SongQueue SSE parse, elapsed sync |
| `test/voice_room_sync_test.dart` | Online count, hoparlör gate |
| `test/gift_session_controller_test.dart` | Gift engine dedupe |
| `test/gift_engine_sse_router_test.dart` | SSE classify |
| `test/gift_duration_parser_test.dart` | Video duration backend parity |
| `test/voice_room_api_doc_test.dart` | API path ↔ kılavuz |
| `test/youtube_stream_resolver_test.dart` | Stream resolve (kaldırılacak yol) |
| `test/features/agora/agora_channel_names_test.dart` | Legacy Agora |

### Skipped (2)

- Detay: `flutter test` çıktısında `~2` — muhtemelen platform/integration skip

---

## Dart analyze (`scripts/dart-analyze-gate.sh`)

| Severity | Sayı | APK engeli |
|----------|-----:|------------|
| ERROR | 0 | — |
| WARNING | 111 | Hayır |
| INFO | 157 | Hayır |

**Kritik WARNING örnekleri:**
- `admin_gift_management_page.dart` — `onError` return type
- `gift_engine_sse_router.dart` — null-aware operator
- Çok sayıda `unused_import`, `unused_element`

---

## API tests (`api/`)

```
npm test — pass (songQueueService + cache tests)
npm run build — TypeScript derleme başarılı
```

---

## CI (GitHub Actions)

| Workflow | PR #306 son push | Durum |
|----------|------------------|-------|
| CI / API + Flutter analyze | `269c1499` | ✅ success |
| CodeQL / java-kotlin | `269c1499` | ✅ success |
| Build release APK | — | ⏸️ Tetiklenmedi |

---

## Eksik testler (yapılması gereken)

1. `scripts/run-acceptance-tests.sh` — 20 madde release gate
2. Müzik senkron integration test (SSE mock + IFrame position)
3. Gift full-screen golden test
4. Auth refresh E2E
5. TRTC join mock test
6. Load: 1000 kullanıcı aynı oda (backend + client)

---

## Sonuç

Unit testler **geçiyor** ancak production parity ve performans hedefleri için **yeterli değil**. APK öncesi acceptance + warning temizliği zorunlu.
