# GitHub PR / dal temizliği

> **Güncel rapor:** [`GITHUB_CLEANUP_REPORT.md`](./GITHUB_CLEANUP_REPORT.md)  
> **Otomasyon:** `.github/workflows/github-cleanup.yml` + `scripts/github-cleanup.sh`

## Politika

| Kural | Açıklama |
|-------|----------|
| PR açma | Agent'lar PR **açmaz** — doğrudan `main` |
| Temizlik | Haftalık CI + `workflow_dispatch` |
| Korunan dal | Yalnızca `main` (aktif geliştirme) |

## Bilinen eski açık PR'lar (kapatılmalı)

Main'de zaten birleşmiş veya obsolete — CI temizliği veya elle **Close**:

| PR | Neden |
|----|--------|
| 1–3 | İlk kurulum / AGENTS — eski |
| 6 | Native UI — main'de |
| 16–17 | Eski sesli oda / premium home |
| 19 | Navbar — eski |
| 21, 24 | Freezed / fal hub — main geçti |
| 33 | Android paket adı — main'de |
| 37 | Scroll/refresh — kısmen main'de |
| 62–64 | Premium 2026 PART 1–3 — main'de |

Son birleşen PR (yerel main): **#136** (`cursor/voice-room-fixes-v2-7009`).

## Remote dal durumu (yerel analiz)

| Kategori | Adet | Aksiyon |
|----------|------|---------|
| `cursor/*` merged into main | ~110 | Remote sil |
| `cursor/*` not merged | ~35 | İncele; obsolete ise PR kapat + dal sil |

Birleşmemiş dalların çoğu eski deneme (native UI, JWT auth, premium home). Aktif parite işi `cursor/p1-fcm-pk-membership-7009` üzerindeyse önce `main`'e merge edin, sonra dalı silin.

## Uygulama

```bash
# Önce dry-run
DRY_RUN=1 bash scripts/github-cleanup.sh

# Uygula (GH_TOKEN veya gh auth)
bash scripts/github-cleanup.sh
```

GitHub Actions kotası: bkz. `docs/GITHUB_ACTIONS_CI.md`.
