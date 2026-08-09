# Acceptance Test Raporu

| Alan | Değer |
|------|--------|
| Tarih | 2026-08-09 10:01:35 UTC |
| Run | local-1786269680 |
| API | https://canlifal.com |
| Geçti | 11 |
| Başarısız | 0 |
| Atlandı | 4 |

## Sonuçlar

| # | Test | Durum | Detay |
|---|------|-------|-------|
| UNBLOCK | Insufficient (overspend) | ✅ PASS | HTTP 400 qty=9 need~4500 bakiye=3550→3550 |
| UNBLOCK | Create room A (owner) | ✅ PASS | roomId=cmslmujm8009jpk08x65gmxz4 |
| UNBLOCK | Create room B (owner) | ✅ PASS | roomId=cmslmujqz009mpk087hu3u75h |
| UNBLOCK | PK create (A→B) | ✅ PASS | battleId=cmslmuo6n009npk08xbm4ck3w |
| UNBLOCK | PK 2-user accept | ✅ PASS | status=active |
| UNBLOCK | PK end | ✅ PASS | status=completed |
| UNBLOCK | Gift SSE event | ✅ PASS | stream içinde gift event |
| UNBLOCK | Host teller approval | ⏸️ BLOCKED | applicationStatus=pending — admin panelden onaylayın veya ACCEPTANCE_ADMIN_* ekleyin |
| UNBLOCK | LIVE create (host) | ⏸️ BLOCKED | NOT_APPROVED — host teller onayı gerekli |
| UNBLOCK | Psychic session create | ✅ PASS | sessionId=cmslmutwj009zpk08t0pjrqdc staffExempt |
| UNBLOCK | Psychic session pending list | ✅ PASS | HTTP 200 |
| UNBLOCK | Psychic accept (teller) | ⏸️ BLOCKED | ACCEPTANCE_TELLER_* yok — falcı hesabı secret olarak ekleyin |
| UNBLOCK | TRTC token A | ✅ PASS | role=anchor room=stage5_local-1786269680 |
| UNBLOCK | TRTC token B | ✅ PASS | role=audience room=stage5_local-1786269680 |
| UNBLOCK | TRTC SDK enterRoom | ⏸️ BLOCKED | Telefon yok — USB hata ayıklama + adb gerekli (Cloud VM'de emülatör yok) |

**API testleri atlandı veya kısmen geçti** (4 atlandı) — istemci testleri bekleniyor.
