# GitHub Temizlik Raporu (yerel analiz)

Oluşturulma: 2026-06-09 12:58 UTC
Kaynak: yerel `git branch -r` (API erişimi gerekmez)
Base: `main`
Son birleşen PR (main geçmişi): **#136**

## Özet

| Metrik | Adet | Aksiyon |
|--------|------|---------|
| `cursor/*` merged into `main` | 110 | Remote silinebilir |
| `cursor/*` not merged | 35 | İncele / kapat veya main'e al |
| Aktif geliştirme dalı | `main` | Koru |

## Silinmeye aday remote dallar (merged)

```
cursor/admin-payment-notifications-7009
cursor/android-internet-permission-763b
cursor/apk-build-fix-7009
cursor/app-fixes-splash-social-push-7009
cursor/auth-chat-freezed-7009
cursor/auth-error-messages-763b
cursor/auth-premium-2026-7009
cursor/auth-social-ux-7009
cursor/canlifal-apk-download-15de
cursor/canlifal-flutter-api-7009
cursor/canlifal-official-config-7009
cursor/canlifal-social-flutter-763b
cursor/cfc-jeton-split-7009
cursor/daily-fortune-flow-7009
cursor/discover-premium-2026-7009
cursor/feed-live-fab-round-7009
cursor/fix-all-errors-7009
cursor/fix-apk-build-quota-7009
cursor/fix-apk-publish-7009
cursor/fix-ci-analyze-warning-7009
cursor/fix-ci-build-apk-7009
cursor/fix-ci-errors-7009
cursor/fix-ci-export-path-7009
cursor/fix-commands-youtube-payment-7009
cursor/fix-env-update-7009
cursor/fix-google-oauth-apk-7009
cursor/fix-music-search-istek-7009
cursor/fix-voice-payment-chat-7009
cursor/fix-voice-payment-stories-7009
cursor/fix-voice-room-provider-7009
cursor/flutter-api-docs-7009
cursor/flutter-full-audit-7009
cursor/flutter-parity-full-7009
cursor/fortune-hub-types-grid-7009
cursor/fortune-type-showcase-cards-7009
cursor/full-backend-parity-7009
cursor/full-parity-all-7009
cursor/gift-premium-2026-7009
cursor/gift-system-7009
cursor/home-canli-falcilar-7009
cursor/home-feed-nav-ui-7009
cursor/home-live-broadcasts-redesign-7009
cursor/home-live-google-fixes-7009
cursor/home-live-profile-763b
cursor/home-pixel-perfect-ui-7009
cursor/home-profile-jeton-invite-ad85
cursor/home-sections-voice-fix-7009
cursor/home-spacing-voice-perf-7009
cursor/home-stats-stories-grid-7009
cursor/jeton-packages-fallback-ui-7009
... ve 60 dal daha
```

## Birleşmemiş cursor dalları (inceleme gerekir)

```
cursor/admin-yonetici-odeme-7009
cursor/android-package-mesutbyrm-7009
cursor/apk-downloads-release-763b
cursor/auth-mockup-ui-7009
cursor/canlifal-api-endpoints-e12f
cursor/canlifal-flutter-app-1c13
cursor/canlifal-flutter-social-7009
cursor/canlifal-native-ui-15de
cursor/dev-env-setup-c87f
cursor/dev-setup-agents-md-0a58
cursor/docs-apk-107-7009
cursor/fix-blank-startup-7009
cursor/fix-ci-app-theme-7009
cursor/fix-install-script-a24d
cursor/fortune-tarot-hub-7009
cursor/freezed-dtos-7009
cursor/home-social-auth-ui-763b
cursor/home-voice-gold-stats-7009
cursor/live-voice-apk-fixes-763b
cursor/merge-pr12-shell-jeton-ad85
cursor/music-playback-fix-7009
cursor/nav-social-subscriptions-7009
cursor/perf-glass-7009
cursor/premium-design-system-7009
cursor/premium-home-page-a24d
cursor/rest-api-jwt-512d
cursor/rest-api-jwt-auth-9821
cursor/setup-dev-environment-a24d
cursor/theme-mode-7009
cursor/v105-changelog-ad85
cursor/voice-music-gift-ux-7009
cursor/voice-music-instant-play-7009
cursor/voice-premium-2026-ui-7009
cursor/voice-responsive-nav-fortune-7009
cursor/youtube-api-key-env-7009
```

## Bilinen eski açık PR'lar (manuel/CI kapatma)

`docs/OPEN_PRS_TRIAGE.md` — #1–3, 6, 16–17, 19, 21, 24, 33, 37, 62–64 main'de; kapatılmalı.

## Uygulama

```bash
# CI (önerilen)
# Actions → GitHub cleanup → Run workflow

# Yerel (GH_TOKEN ile)
DRY_RUN=1 bash scripts/github-cleanup.sh
bash scripts/github-cleanup.sh
```

## İş akışı

- PR otomatik açılmaz
- Geliştirme doğrudan `main` üzerinde
- Haftalık `github-cleanup.yml` birleşmiş PR/dalları temizler
