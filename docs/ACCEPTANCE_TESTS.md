# Release Acceptance Testleri

Release APK (`build-apk.yml`) oluşturulmadan **önce** 20 maddelik acceptance testleri otomatik çalışır. Herhangi biri başarısızsa APK derlenmez.

## Çalıştırma

```bash
# Yerel (üretim API)
export ACCEPTANCE_USER_EMAIL="..."
export ACCEPTANCE_USER_USERNAME="..."
export ACCEPTANCE_USER_PASSWORD="..."
export ACCEPTANCE_ADMIN_EMAIL="..."
export ACCEPTANCE_ADMIN_PASSWORD="..."
bash scripts/run-acceptance-tests.sh
```

Rapor: `docs/ACCEPTANCE_TEST_REPORT.md` ve `docs/ACCEPTANCE_TEST_REPORT.json`

## Test listesi

| # | Test | Katman |
|---|------|--------|
| 1 | Giriş (e-posta) | API |
| 2 | Giriş (kullanıcı adı) | API |
| 3 | Kayıt (endpoint doğrulama) | API |
| 4 | Profil yükleme (`/api/me`) | API |
| 5 | Jeton görüntüleme (`/api/wallet`) | API |
| 6 | Jeton satın alma ekranı (`/api/jeton`) | API |
| 7 | Sohbet odaları | API |
| 8 | SSE bağlantısı | API |
| 9 | Canlı yayın açma | API |
| 10 | Canlı yayına katılma | API |
| 11 | Canlı yayında fal isteği | API |
| 12 | Yayıncının isteği görmesi | API |
| 13 | Yayıncının isteği kabul etmesi | API |
| 14 | Görüntülü görüşme token (Agora/TRTC) | API |
| 15 | Jeton düşümü | API |
| 16 | Admin bildirimi | API |
| 17 | Push cihaz token kaydı | API |
| 18 | Müzik sistemi (!istek) | Flutter test |
| 19 | Tema değiştirme | Flutter test |
| 20 | Performans (API gecikme + tema) | API + Flutter |

## GitHub Secrets (zorunlu)

Repository → **Settings → Secrets and variables → Actions**:

| Secret | Açıklama |
|--------|----------|
| `ACCEPTANCE_USER_EMAIL` | Test kullanıcı e-postası |
| `ACCEPTANCE_USER_USERNAME` | Aynı kullanıcının kullanıcı adı |
| `ACCEPTANCE_USER_PASSWORD` | Şifre |
| `ACCEPTANCE_ADMIN_EMAIL` | Admin hesabı |
| `ACCEPTANCE_ADMIN_PASSWORD` | Admin şifresi |

İsteğe bağlı (varsayılan: `ACCEPTANCE_USER_*`):

- `ACCEPTANCE_HOST_EMAIL` / `ACCEPTANCE_HOST_PASSWORD` — canlı yayın açan hesap
- `ACCEPTANCE_VIEWER_EMAIL` / `ACCEPTANCE_VIEWER_PASSWORD` — izleyici / fal isteği gönderen

## CI davranışı

1. `scripts/run-acceptance-tests.sh` çalışır
2. Başarısızsa iş akışı durur, APK derlenmez
3. Başarısızlıkta `acceptance-test-report` artifact yüklenir
4. Başarılıysa `flutter build apk --release` devam eder

## Notlar

- Testler üretim API (`https://canlifal.com`) üzerinde çalışır
- Canlı yayın testi geçici bir stream oluşturur ve işlem sonunda siler
- Push testi gerçek cihaza bildirim göndermez; yalnızca token kayıt uçlarını doğrular
