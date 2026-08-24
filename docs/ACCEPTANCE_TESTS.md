# Release Gate (9 madde) — APK/AAB öncesi zorunlu

Release APK veya AAB (`build-apk.yml`) oluşturulmadan **önce** 9 maddelik release gate otomatik çalışır. **Herhangi biri başarısızsa APK/AAB ve sürüm etiketi oluşturulmaz.**

## Çalıştırma

```bash
# Yerel (üretim API — madde 3–8 için secrets gerekli)
export ACCEPTANCE_USER_EMAIL="..."
export ACCEPTANCE_USER_USERNAME="..."
export ACCEPTANCE_USER_PASSWORD="..."
export ACCEPTANCE_ADMIN_EMAIL="..."
export ACCEPTANCE_ADMIN_PASSWORD="..."
# İsteğe bağlı: ACCEPTANCE_HOST_*, ACCEPTANCE_VIEWER_*, ACCEPTANCE_TELLER_*

bash scripts/run-release-gate.sh
# Gate 9 (release build) yerelde:
cd mobile && flutter build apk --release
```

Raporlar:

- `docs/RELEASE_GATE_REPORT.md` — tüm 9 madde özeti
- `docs/ACCEPTANCE_TEST_REPORT.md` — API detay (madde 3–8)

## 9 madde listesi

| # | Kontrol | Katman |
|---|---------|--------|
| 1 | `flutter analyze` sıfır hata | Flutter |
| 2 | `flutter test` tamamı geçer | Flutter |
| 3 | Canlı falcı görüntülü görüşme (session + Agora token) | API |
| 4 | Canlı yayın fal isteği (stream + istek + yayıncı listesi) | API |
| 5 | Jeton satın alma bildirimi admin paneline düşer | API |
| 6 | SSE bağlantıları (`/api/chat/rooms/{id}/stream`) | API |
| 7 | Profil ekranı &lt; 2 sn (`/api/me` gecikmesi) | API |
| 8 | Kullanıcı adı ile giriş (`emailOrUsername`) | API |
| 9 | Release build başarılı (`flutter build apk --release`) | CI |

## GitHub Secrets (madde 3–8)

Repository → **Settings → Secrets and variables → Actions**.

**Hızlı kurulum** (repo admin, yerel `gh` oturumu):

```bash
bash scripts/set-acceptance-secrets.sh
bash scripts/acceptance-preflight.sh   # doğrulama
```

| Secret | Açıklama | Varsayılan (secret yoksa) |
|--------|----------|---------------------------|
| `ACCEPTANCE_USER_EMAIL` | Test kullanıcı e-postası | `cursor.test.1786235468@mailinator.com` |
| `ACCEPTANCE_USER_USERNAME` | Kullanıcı adı | `cursorusr1786235468` |
| `ACCEPTANCE_USER_PASSWORD` | Şifre | `CursorTest!1786235468` |
| `ACCEPTANCE_HOST_EMAIL` | Canlı yayın host | `cursor.host.1786235468@mailinator.com` |
| `ACCEPTANCE_HOST_PASSWORD` | Host şifresi | `CursorTest!1786235468` |
| `ACCEPTANCE_ADMIN_EMAIL` | Admin hesabı | — |
| `ACCEPTANCE_ADMIN_PASSWORD` | Admin şifresi | — |

İsteğe bağlı (varsayılan: `ACCEPTANCE_USER_*`):

| Secret | Açıklama |
|--------|----------|
| `ACCEPTANCE_HOST_EMAIL` / `ACCEPTANCE_HOST_PASSWORD` | Canlı yayın açan hesap |
| `ACCEPTANCE_VIEWER_EMAIL` / `ACCEPTANCE_VIEWER_PASSWORD` | Fal isteği gönderen izleyici |
| `ACCEPTANCE_TELLER_EMAIL` / `ACCEPTANCE_TELLER_PASSWORD` | Falcı hesabı |
| `ACCEPTANCE_TELLER_ID` / `ACCEPTANCE_TELLER_USER_ID` | Falcı kimlikleri (otomatik bulunamazsa) |

## CI davranışı

1. `scripts/run-release-gate.sh` — madde 1–8
2. Başarısızsa iş akışı durur; `release-gate-report` artifact yüklenir
3. Başarılıysa `flutter build apk --release` (madde 9) ve `apk-latest` yüklemesi

## Eski 20 maddelik acceptance testleri

Genişletilmiş kontrol listesi için `scripts/run-acceptance-tests.sh` kullanılabilir. CI artık **9 maddelik release gate** ile çalışır.

## Notlar

- Testler üretim API (`https://canlifal.com`) üzerinde çalışır
- **Secret yoksa** release gate dokümante test hesaplarını kullanır (`scripts/acceptance-tests/defaults.sh`)
- **Secret hatalıysa** otomatik olarak aynı dokümante hesaplara düşülür (uyarı loglanır)
- Admin/teller secret yoksa ilgili maddeler `SKIP` olur
- Secret varken ve API testi başarısızsa APK **engellenir**
- Canlı yayın testi geçici stream oluşturur ve işlem sonunda siler
- Jeton testi gerçek ödeme yapmaz; `POST /api/payment/requests` + admin listesi doğrulanır

## Müzik / !istek (M5–M7, release gate dışı)

Sesli oda müzik API doğrulaması (üretim, cihaz gerekmez):

```bash
bash scripts/run-music-acceptance.sh    # api-music-phase 6/6 + M7 probe
bash scripts/m5-preflight.sh            # + jeton kontrolü + voice_hub testleri
```

Raporlar: `docs/API_MUSIC_PHASE_REPORT.md`, `docs/M7_MUSIC_SSE_CAPTURE.md`  
Cihaz testi: `docs/M5_DEVICE_TEST_CHECKLIST.md`
