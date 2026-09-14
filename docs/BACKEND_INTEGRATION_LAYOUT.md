# Backend entegrasyon dosya yerleşimi — Aşama 1

**Amaç:** Backend paketlerini tek kanonik konuma toplamak; byte-identical kopyaları kaldırmak. Flutter davranışı / API uçları bu aşamada değiştirilmedi.

## Öncelik sırası (çelişkide)

1. Üretim: `https://canlifal.com`
2. Mobil sözleşme: [`FLUTTER_ENTegrasyon_KILAVUZU.md`](FLUTTER_ENTegrasyon_KILAVUZU.md)
3. OpenAPI / indeks: [`backend-docs/openapi.json`](../backend-docs/openapi.json)
4. Abacus ZIP (B22, sınıflandırma): [`backend-reference/canlifal_flutter_paketi/`](../backend-reference/canlifal_flutter_paketi/)
5. Abacus devir ağacı: [`backend-docs/abacus-current/`](../backend-docs/abacus-current/)

## Kaldırılan duplicate’ler (Aşama 1)

| Silinen kopya | Kanonik dosya |
|---------------|----------------|
| `abacus-current/priority1/openapi.json` | `backend-docs/openapi.json` |
| `abacus-current/priority1/ENDPOINTS.md` | `backend-docs/ENDPOINTS.md` |
| `abacus-current/priority1/schema.prisma` | `backend-docs/schema.prisma` |
| `abacus-current/priority1/DATABASE_REFERENCE.md` | `backend-docs/DATABASE_REFERENCE.md` |
| `abacus-current/priority3/endpoints_index.json` | `backend-docs/endpoints_index.json` |

## Korunan (farklı içerik veya rol)

- `backend-reference/canlifal_flutter_paketi/openapi.yaml` — ZIP paketi (Sep 12); JSON setinden bağımsız referans
- `backend-reference/.../postman_collection.json` vs `priority3/postman_collection.json` — farklı export’lar
- Legacy `docs/FLUTTER_API_*.md` — silinmedi; kullanılmamalı

## Sonraki aşamalar (bu dosyada yapılmadı)

- Auth/SSE doküman çelişkilerinin netleştirilmesi
- Orphan Abacus datasource’ların UI bağlantısı
- PK / falcı / bahşiş runtime düzeltmeleri
