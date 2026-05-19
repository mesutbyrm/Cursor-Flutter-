# İndirilen APK (yerel kopya)

Bu klasörde **`canlifal-mobile-release.apk`** dosyası tutulabilir; dosya **Git’e eklenmez** (bkz. `.gitignore`).

## Nasıl doldurulur?

1. **GitHub Sürümü:** [APK_DOWNLOAD.md](../APK_DOWNLOAD.md) içindeki sabit indirme bağlantısından indirip bu klasöre kaydedin.
2. **Kendi derlemeniz:** `flutter build apk --release` sonrası kökteki betik:

   ```bash
   ./scripts/copy-apk-to-downloads.sh
   ```

3. **GitHub Actions:** Artifacts’ten indirdiğiniz ZIP içindeki APK’yı buraya kopyalayabilirsiniz.
