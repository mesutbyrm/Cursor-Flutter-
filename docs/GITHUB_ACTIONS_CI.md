# GitHub Actions — kırmızı X (CI başarısız)

## Bu repoda gördüğünüz hata

`main` dalındaki kırmızı **X**, kod hatasından değil; GitHub’ın işi hiç başlatmamasından kaynaklanıyor:

> **The job was not started because recent account payments have failed or your spending limit needs to be increased.**

Repo **özel (private)** olduğu için Actions ücretli kotaya tabidir. Ödeme / harcama limiti sorunu çözülmeden CI ve APK iş akışları **1–3 saniyede** düşer; adım listesi boş kalır.

## Ne yapmalısınız?

1. [github.com/settings/billing](https://github.com/settings/billing) → ödeme yöntemi ve fatura durumunu düzeltin.
2. Gerekirse **Spending limit** artırın (Settings → Billing → Budgets and alerts).
3. Repo → **Actions** → son başarısız koşu → **Re-run all jobs**  
   veya `main`’e küçük bir commit push edin.

Alternatif (ücretsiz Actions dakikası):

- Repoyu **public** yapın (kişisel hesapta public repo’larda Actions kotası genelde ücretsizdir).

## Kod tarafı yeşil mi?

Yerelde doğrulama:

```bash
bash scripts/ci-local.sh
```

Bu script API `npm run build` ve `dart analyze lib` çalıştırır. Yerelde geçiyorsa, faturalandırma düzeldikten sonra GitHub CI de geçmelidir.

## İş akışları

| Dosya | Görev |
|-------|--------|
| `.github/workflows/ci.yml` | API + Flutter analyze (tek job) |
| `.github/workflows/build-apk.yml` | Release APK + `apk-latest` |

APK: https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk
