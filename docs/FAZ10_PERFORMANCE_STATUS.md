# FAZ 10 — Global performance


> **Güncel (2026-09-07):** **`1.0.371+409`** · Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

**Durum:** AUTOMATED_PASS — perf modülleri + `faz10-performance-check.sh`

| Alan | Mevcut |
|------|--------|
| Perf modülleri | `core/performance/*` |
| SSE/RTC cleanup | voice_hub dispose |
| ANR önleme | M1–M12 müzik + PK davet (`1.0.284–285`) |
| Cihaz profil | `device_perf_tuning.dart` |

**Kapanış:** cihaz profil + memory leak audit (FAZ12 öncesi)
