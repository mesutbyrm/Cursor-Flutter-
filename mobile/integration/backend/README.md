# Mobil ↔ backend referans yerleşimi (Aşama 1)

Flutter **çalışma zamanı** yalnızca `https://canlifal.com` (ve isteğe bağlı `GAMES_API_BASE_URL`) kullanır. Bu klasör kod içermez; entegrasyon dosyalarının repodaki **kanonik** konumlarını listeler.

## Mobil kod (uygulama)

| Ne | Yol |
|----|-----|
| Tek sözleşme kılavuzu | [`docs/FLUTTER_ENTegrasyon_KILAVUZU.md`](../../../docs/FLUTTER_ENTegrasyon_KILAVUZU.md) |
| Endpoint sabitleri | [`lib/core/network/api_endpoints.dart`](../lib/core/network/api_endpoints.dart) |
| HTTP + JWT | [`lib/core/network/dio_provider.dart`](../lib/core/network/dio_provider.dart) |
| Abacus FLUTTER_READY katalog | [`lib/core/abacus/abacus_flutter_ready_catalog.dart`](../lib/core/abacus/abacus_flutter_ready_catalog.dart) |
| Abacus auth / me datasource | [`lib/core/abacus/`](../lib/core/abacus/), [`lib/core/me/`](../lib/core/me/) |
| Özellik datasource’ları | [`lib/features/*/data/datasources/`](../lib/features/) |

## Repo backend referansları (salt okuma)

| Ne | Yol |
|----|-----|
| OpenAPI + indeks (parity betikleri) | [`backend-docs/openapi.json`](../../../backend-docs/openapi.json), [`endpoints_index.json`](../../../backend-docs/endpoints_index.json) |
| Abacus devir paketi (priority 1–3) | [`backend-docs/abacus-current/`](../../../backend-docs/abacus-current/) |
| Abacus ZIP paketi (BÖLÜM 22, TS kaynak) | [`backend-reference/canlifal_flutter_paketi/`](../../../backend-reference/canlifal_flutter_paketi/) — **değiştirilmez** |

## Eski / legacy dokümanlar

`docs/FLUTTER_API_DOCS.md`, `FLUTTER_API_DOKUMANTASYONU.md` vb. — yalnızca arka plan. **Çelişkide** `FLUTTER_ENTegrasyon_KILAVUZU.md` geçerlidir.

Detay: [`docs/BACKEND_INTEGRATION_LAYOUT.md`](../../../docs/BACKEND_INTEGRATION_LAYOUT.md).
