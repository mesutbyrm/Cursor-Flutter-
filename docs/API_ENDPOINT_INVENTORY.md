# API Endpoint Envanter — Phase 2

**Üretim:** `bash scripts/flutter-api-endpoint-inventory.sh`  
**Ham JSON:** `docs/API_ENDPOINT_INVENTORY.json`

## Özet (son üretim)

| Metrik | Değer |
|--------|--------|
| `static const` path | ~308 |
| `static String` builder | ~202 |
| `ApiEndpoints.<name>` kullanımı **0 dosya** | ~29 (manuel inceleme — **silinmedi**) |

## Kurallar

- `usage_files == 0` tek başına silme nedeni **değildir** (reflection, string path, generated, docs).
- 404 probe: `docs/MISSING_ENDPOINTS_FLUTTER_ACTIVE.md` — fallback zinciri korunur.
- Bu fazda **endpoint silinmedi**.

## Silinen endpoint kanıtı

*Yok.*
