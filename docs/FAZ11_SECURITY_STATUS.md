# FAZ 11 — Security + error handling


> **Güncel (2026-09-07):** **`1.0.371+409`** · Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

**Durum:** AUTOMATED_PASS — `faz11-security-scan.sh`

| Alan | Durum |
|------|--------|
| ApiException / HTML guard | ✅ |
| JWT secure storage | ✅ |
| JsonContentTypeGuard | ✅ |
| Secret scan CI | ✅ `faz11-security-scan.sh` (node_modules hariç) |

**Testler:** `api_exception_test.dart`, `json_content_type_guard`
