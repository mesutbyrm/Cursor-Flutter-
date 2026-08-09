# Acceptance Test Raporu

| Alan | Değer |
|------|--------|
| Tarih | 2026-08-09 10:11:39 UTC |
| Run | local-1786270283 |
| API | https://canlifal.com |
| Geçti | 13 |
| Başarısız | 0 |
| Atlandı | 2 |

## Sonuçlar

| # | Test | Durum | Detay |
|---|------|-------|-------|
| UNBLOCK | Insufficient (overspend) | ✅ PASS | HTTP 400 qty=8 need~4000 bakiye=3400→3400 |
| UNBLOCK | Create room A (owner) | ✅ PASS | roomId=cmsln7hkg00b8pk0893gzvqmz |
| UNBLOCK | Create room B (owner) | ✅ PASS | roomId=cmsln7hov00bbpk08h4heqqzz |
| UNBLOCK | PK create (A→B) | ✅ PASS | battleId=cmsln7mdj00bcpk08ws39f4wu |
| UNBLOCK | PK 2-user accept | ✅ PASS | status=active |
| UNBLOCK | PK end | ✅ PASS | status=completed |
| UNBLOCK | Gift SSE event | ✅ PASS | stream içinde gift event |
| UNBLOCK | Host teller approval | ✅ PASS | zaten onaylı tellerId=cmsl2ix6l008cns087j17rts6 |
| UNBLOCK | LIVE create (host) | ✅ PASS | streamId=cmsln7rp600bppk08m6wwerzu |
| UNBLOCK | Psychic session create | ✅ PASS | sessionId=cmsln7s4900bupk08odccgkd1 staffExempt |
| UNBLOCK | Psychic session pending list | ✅ PASS | HTTP 200 |
| UNBLOCK | Psychic accept (teller) | ⏸️ BLOCKED | ACCEPTANCE_TELLER_* yok — falcı hesabı secret olarak ekleyin |
| UNBLOCK | TRTC token A | ✅ PASS | role=anchor room=stage5_local-1786270283 |
| UNBLOCK | TRTC token B | ✅ PASS | role=audience room=stage5_local-1786270283 |
| UNBLOCK | TRTC SDK enterRoom | ⏸️ BLOCKED | Telefon yok — USB hata ayıklama + adb gerekli (Cloud VM'de emülatör yok) |

**API testleri atlandı veya kısmen geçti** (2 atlandı) — istemci testleri bekleniyor.
