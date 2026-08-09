# Aşama 6 — Hediye + Jeton + SSE Acceptance Raporu

| Alan | Değer |
|------|--------|
| Tarih | 2026-08-09 UTC |
| API | https://canlifal.com |
| Flutter sürüm | 1.0.144+178 |
| Dal | `cursor/backend-flutter-sync-0cde` |
| Gerçek cihaz | **Yok** (`adb devices` boş, KVM yok) |
| Test hesabı | `cursor.test.1786235468@mailinator.com` — jeton bakiye **0** |

## Özet

Flutter tarafında **"0 Jeton atıldı"** kök nedeni giderildi: backend `coinCost`/`price` toplam jeton olarak parse ediliyor, katalog zenginleştirmesi sıfır `totalCoin` dolduruyor, send yanıtı `spentAmount`/`newBalance` kullanılıyor, yetersiz bakiye `insufficient_jeton` parse ediliyor.

**500 Jeton uçtan uca testi** ve **iki cihazlı receiver/animation** testleri bu ortamda **BLOCKED** — fiziksel Android cihaz ve ≥500 jeton bakiyeli hesap yok.

---

## 500 JETON (BLOCKED-BY-TEST-ACCOUNT)

| Alan | Değer |
|------|--------|
| BEFORE | 0 (API `/api/me`) |
| GIFT | `elmas` — katalog fiyatı 500 |
| ACTUAL SPENT | — (gönderim reddedildi) |
| AFTER | 0 |
| TRANSACTION | HTTP 400 `insufficient_jeton` |
| UI DISPLAY | Kod düzeltmesi: backend `spentAmount`/`jetonAmount` kullanılır; `jetonAmount <= 0` UI'da gizlenir — **gerçek cihazda doğrulanmadı** |

---

## Sonuç tablosu

| FEATURE | RESULT | ROOT CAUSE | FIX | RETEST |
|---------|--------|------------|-----|--------|
| GIFT CATALOG | **PASS** | — | `GET /api/gifts/types?platform=mobile` — 25 hediye, fiyat backend'den | API `api-gift-phase.sh` |
| GIFT SEND | **BLOCKED-BY-TEST-ACCOUNT** | Test hesabı 0 jeton | `chat_room_gifts_remote_datasource` tam yanıt parse; `giftTypeId` + `receiverUserId` | ≥500 jeton hesabı + cihaz gerekli |
| 500 JETON DEDUCTION | **BLOCKED-BY-TEST-ACCOUNT** | Bakiye 0 | Backend transaction source of truth; local `balance -=` yok | Fonlu hesap + cihaz |
| BALANCE UPDATE | **PASS** (kod) / **BLOCKED** (cihaz) | Eski: boş `VoiceGiftSendResult` | `newBalance` + `walletBalancesProvider` invalidate | Cihaz retest |
| INSUFFICIENT BALANCE | **PASS** | — | `insufficient_jeton` → `ApiErrorCode.insufficientJetons` | API 400 doğrulandı |
| RECEIVER EVENT | **BLOCKED-BY-DEVICE** | İki cihaz yok | SSE `gift` event → `gift_session_controller` | Device A+B |
| GIFT ANIMATION | **BLOCKED-BY-DEVICE** | Cihaz yok | Animasyon yalnızca SSE kaynaklarından; sıfır jeton filtre | Device B |
| RANKING | **BLOCKED-BY-DEVICE** | Gift send yapılamadı | Local ranking artırımı kaldırıldı; backend event beklenir | Fonlu hesap + cihaz |
| SSE CONNECT | **PASS** | — | `GET /api/chat/rooms/{id}/stream` Bearer ile açılıyor | API 5s probe |
| SSE EVENT PARSING | **PASS** (kod) / **BLOCKED** (cihaz) | `amount` quantity ile karışıyordu | `parseGiftEvent` `coinCost` total; `GiftEngineSseRouter` | Unit test + cihaz |
| SSE RECONNECT | **BLOCKED-BY-DEVICE** | Cihaz yok | Mevcut exponential backoff (kılavuz §5) | Manuel cihaz testi |
| SSE CLEANUP | **BLOCKED-BY-DEVICE** | Cihaz yok | Oda dispose'da stream kapatma mevcut | Manuel cihaz testi |
| DUPLICATE EVENT PROTECTION | **PASS** (kod) | Eksik dedupe anahtarları | `giftHistoryId`/`queueItemId`/`transactionId`; `processedEventIds` | Unit + cihaz retest |
| ROOM SWITCH | **BLOCKED-BY-DEVICE** | Cihaz yok | Tek oda SSE lifecycle mevcut | Manuel cihaz testi |

---

## Kod düzeltmeleri (bu oturum)

1. **`live_gifts_remote_datasource.dart`** — `coinCost`/`price` toplam jeton; `transactionId` → `giftHistoryId` dedupe
2. **`gift_event_catalog_enricher.dart`** — sıfır `totalCoin` için katalog `price × quantity`; erken return jeton enrich'i atlamıyor
3. **`chat_room_gifts_remote_datasource.dart`** — send yanıtından `spentAmount`, `newBalance`, `giftEvent`
4. **`voice_gift_revenue.dart`** / **`live_field_gift_api.dart`** — genişletilmiş send result modeli
5. **`gift_session_controller.dart`** — katalog enrich önce; `jetonAmount <= 0` skip; çoklu dedupe key
6. **`voice_premium_gift_panel_2026.dart`** — snackbar backend `spentAmount`; wallet refresh
7. **`live_recent_gifters_box.dart`** — sıfır jeton satırları gizle
8. **`api_error_code.dart`** / **`api_exception.dart`** — `insufficient_jeton` / `INSUFFICIENT_BALANCE`
9. **`live_pk_gift_stabilize_test.dart`** — jeton parse + catalog enrich testleri
10. **`scripts/acceptance-tests/api-gift-phase.sh`** — katalog, auth, yetersiz bakiye, SSE API kapısı

---

## API test çıktısı

```
✅ CATALOG — 25 hediye
✅ AUTH — token
✅ WALLET — bakiye=0
✅ INSUFF — HTTP 400 insufficient_jeton
✅ SSE — stream açık
```

Detay: `mobile/docs/API_GIFT_PHASE_REPORT.md`

---

## Aşama 6 kararı

| Durum | Açıklama |
|-------|----------|
| **KOD** | 500 Jeton / "0 Jeton" entegrasyon hataları düzeltildi |
| **API** | Katalog, yetersiz bakiye, SSE connect PASS |
| **CİHAZ** | Tüm iki cihazlı ve 500 jeton E2E maddeleri BLOCKED |
| **Müzik / !istek aşaması** | **Geçilmez** — gerçek cihaz + fonlu hesap ile retest gerekli |

### Retest için gerekenler

1. İki fiziksel Android cihaz (Device A sender, Device B receiver)
2. Test hesabında **≥500 jeton** (admin grant veya satın alma)
3. Aynı voice room'da A→B `elmas` (500) gönderimi
4. BEFORE/AFTER bakiye, B'de SSE gift event + animasyon, ranking backend ile karşılaştırma
