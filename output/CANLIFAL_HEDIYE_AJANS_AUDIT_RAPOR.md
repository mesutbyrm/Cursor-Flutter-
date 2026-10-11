# Canlifal — Hediye & Ajans denetim raporu (Flutter parity)

> **Kaynak:** canlifal.com `full-source` · **PR #41** squash-merge · commit **`c71ecd9`**
> **Mobil repo:** Cursor-Flutter- · entegrasyon kılavuzu §9 + `docs/CANLIFAL_YENi_ENDPOINTLER_FLUTTER_REHBER.md`

## 1. Hediye dağılımı (sunucu — mobil değişiklik gerekmez)

Üretimde `calculateGiftDistribution(totalAmount, roomType, isRecipientOwner)`:

| Adım | Kural |
|------|--------|
| Platform | `vr_platform_percent` (varsayılan %50) önce kesilir |
| Sahibe hediye | Kalan tamamen oda/yayın sahibine |
| Misafir koltuğa | Kalan `vr_owner_share_guest_gift` (varsayılan %30) sahibe, geri kalan alıcıya |
| FREE oda | Sahip payı her zaman 0 |

Sesli oda (`/api/chat/rooms/{id}/gifts`) ve canlı yayın (`/api/video-streams/{id}/gifts`) aynı helper’ı kullanır. Flutter hediye gönderimi mevcut uçları kullanmaya devam eder; tutar sunucuda hesaplanır.

## 2. Ajans toplu Jeton — PR #41 (mobil ✅)

### GET `/api/agency/purchase`

| Query | Mod | Sonuç |
|-------|-----|--------|
| `?jeton=N` | A | İndirimli TL (`discountPercent`, `savedTl`) |
| `?tl=X` | B | Bonus jeton (`bonusJeton`, `totalJeton`, `bonusPercent`) |

Yanıt `data.quote` alanı: `mode`, `jetonAmount`, `bonusJeton`, `totalJeton`, `normalPriceTl`, `finalPriceTl`, `discountPercent`, `bonusPercent`, `savedTl`.

### POST `/api/agency/purchase`

- Mod A: `{ "jeton": N, "paymentMethod": "bank_transfer"|"papara"|"whatsapp"|"other", ... }`
- Mod B: `{ "tl": X, "paymentMethod": ..., ... }`

Onay sonrası `requestedAmount` = **`totalJeton`** (bonus dahil) ajans cüzdanına yüklenir.

### Flutter

| Bileşen | Dosya |
|---------|--------|
| Teklif + sipariş | `mobile/lib/features/agency/data/datasources/agency_wallet_datasource.dart` |
| UI (Jeton↔TL / TL→bonus) | `mobile/lib/features/agency/presentation/pages/agency_wallet_page.dart` |
| Testler | `mobile/test/features/agency/agency_purchase_quote_test.dart` |

## 3. Admin (web ağırlıklı)

PR #41 admin panelinde `vr_platform_percent`, `vr_owner_share_guest_gift`, `agency_purchase_bonus_pct` ayarlarını ve ödeme onayında `processAgencyCommission` / ajans cüzdan yüklemesini içerir. Mobil admin finans/ödeme akışları mevcut `/api/admin/*` uçlarıyla uyumludur; yeni platform ayar ekranı web’de kalır.

## 4. Doğrulama checklist (cihaz)

- [ ] Ajans sahibi → Cüzdan → Toplu Jeton → **Jeton → TL** teklif + sipariş
- [ ] Aynı ekran → **TL → bonus** teklif + sipariş (`totalJeton` > `jetonAmount`)
- [ ] Admin ödeme onayı → ajans cüzdan bakiyesi `totalJeton` kadar artar
- [ ] Sesli odada misafire hediye → sahip/alıcı payları sunucu loglarında yeni modele uygun
