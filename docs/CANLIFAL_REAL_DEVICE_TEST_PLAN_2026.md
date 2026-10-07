# CANLIFAL — Gerçek Cihaz Test Planı 2026 (Cihaz A + Cihaz B)

> 2026-10-07 · Bu plan henüz **koşulmadı**: tüm satırlar **BLOCKED**.
> Ön koşul: iki Android cihaz, aynı APK sürümü, iki ayrı hesap (A = kullanıcı/danışan, B = owner/falcı).
> Her test öncesi **Ayarlar → Hakkında → sürüm satırına uzun bas → Diagnostics** açılır. "Ayrıntılı izleme" ve dosya loglama açılır. Test bitince ZIP dışa aktarılır.

## Kayıt formatı (her test için)

```
TEST: VOICE-001   CİHAZ: A   SÜRÜM: 1.0.x+y   TARİH: …
SONUÇ: PASS | FAIL | BLOCKED
SÜRE: … ms        TRACE: CF-TRACE-…
ROOM: …  SESSION: …  TRTC: joined/role/localAudio  SSE: connected/endpoint
HATA KODU / OLAY / STATE / ZAMAN DAMGASI: …
```

## VOICE
| ID | Adımlar | Beklenen (A) | Beklenen (B) | İlgili bulgu |
|---|---|---|---|---|
| VOICE-001 | A odaya girer (koltuksuz) | Mikrofon göstergesi **kapalı**; log `TRTC_JOIN` role=audience, `LOCAL_AUDIO_DISABLE` | A'nın sesi gelmez | VOICE-001 |
| VOICE-002 | A koltuğa oturur → mikrofon açar → konuşur | Mikrofon açılma süresi < 1 sn; `LOCAL_AUDIO_ENABLE` | A'yı duyar | VOICE-003 |
| VOICE-003 | A koltuktan iner | Anında `LOCAL_AUDIO_DISABLE`, seat=null | A'nın sesi **hemen** kesilir | #12 |
| VOICE-004 | A odadan çıkar → ana sayfa | `TRTC_LEAVE`, SSE disconnect, heartbeat/polling stop | A listede görünmez (≤ 5 sn) | VOICE-004, #7 |
| VOICE-005 | B (owner) mikrofonunu açar | A'nın mikrofonu **değişmez** | — | #16 |
| VOICE-006 | A oda X'ten oda Y'ye geçer | X sesi gelmez, X SSE kapanır, Y'ye tek TRTC join | — | VOICE-002, #13 |
| VOICE-007 | A koltuktayken uygulamayı zorla kapatır | — | A'nın koltuğu ≤ 90 sn, presence ≤ 5 dk boşalır (ölçülecek) | #6, #7 |
| VOICE-008 | A Home tuşu → 30 sn → geri döner | Ses/SSE/presence yeniden uzlaşır | A görünür kalır | §39 |
| VOICE-009 | Owner odaya girer | Owner koltuğa ≤ 2 sn oturur | — | #3 |

## LIVE
| ID | Adımlar | Beklenen |
|---|---|---|
| LIVE-001 | B yayın açar, A izler, A çıkar | A çıkınca B'nin sesi A'da kesilir; A'nın mikrofonu hiç açılmaz |
| LIVE-002 | A misafir olur → iner | İnince A'nın sesi gitmez |
| LIVE-003 | Yayın arka plan → ön plan | Video/ses yeniden bağlanır, çift join yok |

## FORTUNE (canlı fal)
| ID | Adımlar | Beklenen (A ve B) |
|---|---|---|
| FORTUNE-001 | A istek gönderir, B kabul eder | Her iki cihazda aynı `sessionId` + `roomId`; ACCEPTED → ROOM_READY → RTC_CONNECTED → TIMER_ACTIVE ≤ 10 sn |
| FORTUNE-002 | B kabule iki kez hızlı basar (veya iki cihazdan) | Tek oda, tek bildirim (şu an **beklenen FAIL**: B-C1) |
| FORTUNE-003 | A istek gönderir, uygulamayı zorla kapatır, B uygulamayı yeniden açar | İstek ≤ 3 dk sonra artık gösterilmez (şu an **beklenen FAIL**: B-C2) |
| FORTUNE-004 | A 10 kez hızlı tıklar | Tek istek (PR #449) |
| FORTUNE-005 | İki cihazın timer farkı | ≤ 1 sn |
| FORTUNE-006 | A arka plan → ön plan (seans sırasında) | Timer kaymaz, ses/görüntü geri gelir |

## PK
| ID | Adımlar | Beklenen |
|---|---|---|
| PK-001 | A, B'ye PK isteği | İstek B'de **doğru ekranda** (sesli/canlı) |
| PK-002 | Kabul → skor | İki cihazda aynı battleId, endsAt, skor |
| PK-003 | Oyun PK (`/api/pk/*`) | REST ve SSE aynı veriyi gösterir (şu an **riskli**: PK-001 bulgusu) |

## GIFT
| ID | Adımlar | Beklenen |
|---|---|---|
| GIFT-001 | A 500 jeton hediye gönderir | A: bakiye −500, animasyon. B: animasyon ≤ 2 sn, sıralama ve alınan jeton güncellenir. Log: `giftHistoryId`, `queueId`, `durationMs`, `videoUrl` |
| GIFT-002 | Süresi > 12 sn video hediye | **Tamamı** oynar (şu an **beklenen FAIL**: GIFT-001) |
| GIFT-003 | Aynı hediye bir kez | İki cihazda birer kez oynar (çift yok) |

## PROFILE / ADMIN / PERF / MEMORY
| ID | Adımlar | Beklenen |
|---|---|---|
| PROFILE-001 | Profil aç | ≤ 2 sn; yavaş istek Diagnostics → Network'te görünür |
| ADMIN-001 | Mobil admin: istatistik, kullanıcı ara, hediye yönet | Şu an **beklenen FAIL** (401). Düzeltme sonrası 200 |
| PERF-001 | 10 dk sesli oda | UI FREEZE kaydı yok; jank < %1 |
| MEMORY-001 | 10× oda gir/çık | `CfResourceTracker` sızıntı = 0 |
