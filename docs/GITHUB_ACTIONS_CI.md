# GitHub Actions — CI ve APK



> **Güncel (2026-09-08):** **`1.0.391+429`** · Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

**Son güncelleme:** 2026-09-08

## Güncel durum

| İş akışı | Durum | Not |
|----------|--------|-----|
| `ci.yml` | ✅ PASS | Analyze + flutter test (1081+) |
| `build-apk.yml` | ✅ **FINAL PASS** | [Run 34241450261](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/34241450261) |
| `build-aab.yml` | ⏸ manuel | Play Store AAB — `workflow_dispatch` · `ANDROID_KEYSTORE_*` · adımlar: `bash scripts/print-ci-aab-steps.sh` |
| `apk-latest` | ✅ | `1.0.391+429` |
| `[skip ci]` push | ✅ | CI/CodeQL/APK/cleanup atlanır — docs/CI-only commit |

## İş akışları

| Dosya | Görev |
|-------|--------|
| `.github/workflows/ci.yml` | API build + dart analyze + flutter test + FAZ0 |
| `.github/workflows/build-apk.yml` | Release gate + APK + apk-latest + `LATEST_APK_BUILD.md` |
| `.github/workflows/build-aab.yml` | Play Store AAB (manuel, keystore secret) |
| `.github/workflows/build-debug-apk.yml` | Debug APK (CI sonrası) |
| `.github/workflows/codeql.yml` | Güvenlik analizi |
| `.github/workflows/github-cleanup.yml` | Birleşmiş `cursor/*` dal temizliği |

## Yerel doğrulama

```bash
bash scripts/ci-local.sh
bash scripts/run-release-gate.sh   # Gate 1–8
bash scripts/print-build-status.sh
```

## Ödeme / kota hatası (tarihsel)

Repo özel ise Actions kotası gerekebilir. Eski hata:

> The job was not started because recent account payments have failed…

Çözüm: [github.com/settings/billing](https://github.com/settings/billing) → ödeme / spending limit → Re-run jobs.

## APK

https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk

Detay: [`LATEST_APK_BUILD.md`](LATEST_APK_BUILD.md) · [`APK_DOWNLOAD.md`](../APK_DOWNLOAD.md)

## Play Store AAB (manuel)

```bash
bash scripts/print-ci-aab-steps.sh          # GitHub Actions adımları
bash scripts/play-keystore-secrets-cheatsheet.sh
bash scripts/p2-prep-go.sh                # agent P2 GO
```
