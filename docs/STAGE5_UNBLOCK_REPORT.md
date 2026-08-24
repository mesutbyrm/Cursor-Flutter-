# Acceptance Test Raporu

| Alan | Değer |
|------|--------|
| Tarih | 2026-08-09 10:50:39 UTC |
| Run | local-1786272617 |
| API | https://canlifal.com |
| Geçti | 13 |
| Başarısız | 0 |
| Atlandı | 2 |

## Sonuçlar

| # | Test | Durum | Detay |
|---|------|-------|-------|
| UNBLOCK | Insufficient (overspend) | ✅ PASS | HTTP 400 qty=7 need~3500 bakiye=2850→2850 |
| UNBLOCK | Create room A (owner) | ✅ PASS | roomId=cmslolij40159pk08b4u2inwm |
| UNBLOCK | Create room B (owner) | ✅ PASS | roomId=cmslolin2015cpk08kpl4rdgh |
| UNBLOCK | PK create (A→B) | ✅ PASS | battleId=cmslolrh6015dpk08grhsk2zc |
| UNBLOCK | PK 2-user accept | ✅ PASS | status=active |
| UNBLOCK | PK end | ✅ PASS | status=completed |
| UNBLOCK | Gift SSE event | ✅ PASS | stream içinde gift event |
| UNBLOCK | Host teller approval | ✅ PASS | zaten onaylı tellerId=cmsl2ix6l008cns087j17rts6 |
| UNBLOCK | LIVE create (host) | ✅ PASS | streamId=cmslolwtw015qpk08i37vqd5c |
| UNBLOCK | Psychic session create | ✅ PASS | sessionId=cmslolx7x015vpk08yzskjgpl staffExempt |
| UNBLOCK | Psychic session pending list | ✅ PASS | HTTP 200 |
| UNBLOCK | Psychic accept (teller) | ⏸️ BLOCKED | ACCEPTANCE_TELLER_* yok — falcı hesabı secret olarak ekleyin |
| UNBLOCK | TRTC token A | ✅ PASS | role=anchor room=stage5_local-1786272617 |
| UNBLOCK | TRTC token B | ✅ PASS | role=audience room=stage5_local-1786272617 |
| UNBLOCK | TRTC SDK enterRoom | ⏸️ BLOCKED | Telefon yok — USB hata ayıklama + adb gerekli (Cloud VM'de emülatör yok) |

**API testleri atlandı veya kısmen geçti** (2 atlandı) — istemci testleri bekleniyor.
