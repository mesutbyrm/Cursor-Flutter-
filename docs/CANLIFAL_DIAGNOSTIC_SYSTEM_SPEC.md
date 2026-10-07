# CANLIFAL — Diagnostic System Spec (mevcut durum + eksikler)

> 2026-10-07 · Yalnız denetim. Kod değişikliği yok.

## 1. Bugün kodda olanlar (`mobile/lib/core/diagnostics/`, 2.043 satır)

| Bileşen | Dosya | Durum |
|---|---|---|
| Kategorili bellek kaydı, gizlilik süzgeci | `cf_diag.dart` | Var (PR #449) |
| İz kimliği `CF-TRACE-…`, tekil-uçuş | `cf_trace.dart` | Var (PR #449) |
| Kare/jank + UI donma bekçisi | `cf_monitors.dart` | Var (PR #449) |
| Kendi kendine tanı | `cf_self_check.dart`, `features/debug/presentation/pages/cf_diagnostics_page.dart` | Var (PR #449) |
| Dosya loglama, `summary.json`/`errors.json`, ZIP dışa aktarma | `cf_diagnostic_logger.dart`, `cf_diagnostic_export.dart` | Var (Cursor `771f3966`) |
| Kaynak takibi (CREATED/ACTIVE/DISPOSED) | `cf_resource_tracker.dart` | Var (Cursor `720a3148`) |
| Kök neden analizörü, senaryolar | `cf_root_cause.dart`, `scenarios/*` | Var (Cursor) |

Giriş yolu: Ayarlar → Hakkında → sürüm satırına uzun bas (`/settings/diagnostics`).

## 2. İstenen ↔ mevcut (boşluk analizi)

| İstenen | Mevcut | Boşluk |
|---|---|---|
| Dashboard: AUTH, TRTC, SSE, ROOM, SEAT, AUDIO, VIDEO, PK, GIFT, FORTUNE, TIMER, API, MEMORY | Diagnostics/Performance/Network/TRTC/SSE/Errors sekmeleri | ROOM, SEAT, AUDIO, PK, GIFT, TIMER için ayrı canlı panel yok |
| Olay log formatı `[hh:mm:ss.mmm] EVENT key=value` | `CfDiag` + `CfDiagnosticLogger` | Olay adları standart değil (`ROOM_JOIN`, `TRTC_JOIN_SUCCESS`, `SEAT_ASSIGNED`… sözlüğü yok) |
| JSON alanları: timestamp, category, severity, event, roomId, sessionId, streamId, battleId, userId, requestId, endpoint, durationMs, stateBefore, stateAfter, error, stackTrace | Kısmi | `stateBefore/stateAfter`, `battleId`, `requestId` tutarlı değil |
| Dosya adı `canlifal_diagnostic_YYYY-MM-DD_HH-mm.json/.txt` | Oturum klasörü + `summary.json`/`errors.json` | Adlandırma farklı, `.txt` özeti eklenmeli |
| Kaynak kimliği `SSE#123`, `TRTC#44`… ve DUPLICATE RESOURCE tespiti | `CfResourceTracker` | TRTC/SSE servislerinin hepsi kayıt yapmıyor (kapsam ölçülmedi) |
| Otomatik CRITICAL tespitleri (aşağıda) | Yok / kısmi | Kurallar yazılmalı |

## 3. Otomatik hata tespit kuralları (yazılacak)

| Kural | Koşul | Severity |
|---|---|---|
| AUDIO_ACTIVE_AFTER_SEAT_LEAVE | `seatIndex==null && localAudio==true` > 500 ms | CRITICAL |
| AUDIO_ACTIVE_WITHOUT_SEAT | sesli odada koltuksuz `localAudio==true` | CRITICAL |
| TRTC_JOINED_TWICE | `enterRoom` başarılıyken ikinci `enterRoom` (herhangi bir yönetici) | CRITICAL |
| SSE_CONNECTED_TWICE | aynı endpoint için aktif iki kaynak | CRITICAL |
| STALE_ROOM_EVENT | olay `roomId` ≠ aktif oda | CRITICAL |
| STALE_SESSION_EVENT | olay `sessionId` ≠ aktif seans | CRITICAL |
| TIMER_AFTER_END | seans `ended` iken timer çalışıyor | CRITICAL |
| TIMER_DRIFT | `|clientRemaining − serverRemaining| > 2 sn` | CRITICAL |
| DUPLICATE_GIFT | aynı `giftHistoryId` iki kez oynatıldı | CRITICAL |
| ROOM_ID_MISMATCH | REST `roomId` ≠ TRTC `strRoomId` | CRITICAL |
| API_SLOW | > 5 sn HIGH, > 2 sn MEDIUM | HIGH/MEDIUM |
| SSE_RECONNECT_LOOP | 60 sn'de > 5 yeniden bağlanma | HIGH |
| PROFILE_SLOW | profil > 2 sn | HIGH |

## 4. Gizlilik
Token, JWT, şifre, secret, userSig, e-posta asla yazılmaz. Mevcut süzgeç: `CfDiag.sanitize` / `sanitizeText`. Yeni kurallar da bu süzgeçten geçmeli.
