# Play Store — agent hazırlık checklist (1 sayfa)


> **Sürüm:** `1.0.371+409` · Cihaz P0/P1 **sonra** · Agent prep **✅ TAMAM**

## Komutlar

```bash
bash scripts/p2-prep-go.sh              # P2 agent GO (özet)
bash scripts/p1-prep-go.sh              # P1 checklist GO
bash scripts/p2-prep-all.sh             # tam (AAB + app access + FGS + keystore)
bash scripts/play-aab-readiness.sh      # keystore + Gradle + Sign-In
bash scripts/play-store-checklist.sh    # Console adımları
bash scripts/print-play-console-app-access.sh  # App access metni
bash scripts/print-play-foreground-service-declaration.sh  # FGS kopyala-yapıştır
bash scripts/print-play-data-safety-summary.sh  # Data safety özeti
bash scripts/print-play-content-rating-summary.sh  # IARC
bash scripts/print-play-store-listing.sh      # Store listing taslak
bash scripts/print-ci-aab-steps.sh            # GitHub Actions AAB
bash scripts/print-play-target-audience-summary.sh  # Target audience + ads
bash scripts/print-go-commands.sh             # GO / prep indeks
bash scripts/print-agent-prep-status.sh       # prep envanter
bash scripts/agent-prep-tamam.sh              # prep paketi doğrula
bash scripts/print-play-upload-day-checklist.sh  # yükleme günü
bash scripts/p2-prep-now.sh             # özet
bash scripts/build-play-aab.sh          # AAB yerel (keystore gerekir)
```

## CI secret (GitHub Actions)

| Secret | Açıklama |
|--------|----------|
| `ANDROID_KEYSTORE_BASE64` | `release.keystore` base64 |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore şifresi |
| `ANDROID_KEY_ALIAS` | Key alias |
| `ANDROID_KEY_PASSWORD` | Key şifresi |

Yerel: `cp mobile/android/key.properties.example mobile/android/key.properties`

Secret kurulum: `bash scripts/play-keystore-secrets-cheatsheet.sh`

## AAB CI workflow

GitHub → **Actions** → **Build release AAB** → Run workflow (dal `main`)  
Artifact: `canlifal-release-aab` · Workflow: `.github/workflows/build-aab.yml`

## Play Console test hesapları

| Rol | E-posta | Şifre |
|-----|---------|-------|
| Danışan | `cursor.test.1786235468@mailinator.com` | `CursorTest!1786235468` |
| Host | `cursor.host.1786235468@mailinator.com` | aynı |

## Yükleme günü (P0+P1 PASS sonrası)

1. Closed test track → AAB yükle
2. Testers davet
3. Data safety + foreground service formları
4. 14 gün closed test → Production access

Detay: [`P2_PLAY_STORE_START.md`](P2_PLAY_STORE_START.md) · [`PLAY_STORE_PRODUCTION_ACCESS.md`](PLAY_STORE_PRODUCTION_ACCESS.md)
