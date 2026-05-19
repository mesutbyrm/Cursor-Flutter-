# Canlifal Mobile

## Cursor Cloud specific instructions

### Ortam

- Flutter SDK: `/opt/flutter/bin` (PATH'te olmalı)
- Node.js: `nvm` ile kurulu; API geliştirmesi için `api/` klasörü
- Güncelleme betiği: `bash scripts/cursor-update.sh` (`.cursor/environment.json` içinden çağrılır)
- **Prisma migrate** yalnızca `api/.env` içinde `DATABASE_URL` tanımlıysa çalışır; aksi halde atlanır (bu normaldir)

### Proje yapısı (Clean Architecture)

```
lib/
├── app/           # Router, tema
├── core/          # ApiClient, JWT, storage
├── domain/        # Entities, repository arayüzleri
├── data/          # Datasources, repository impl
└── presentation/  # Riverpod, ekranlar
```

Ekranlar `lib/presentation/features/*/screens/` altındadır. Eski `lib/src/` yolu kullanılmaz.

### Geliştirme komutları

```bash
flutter pub get
flutter analyze
flutter test

# Yerel JWT API (isteğe bağlı)
docker compose up -d
cp api/.env.example api/.env
cd api && npm ci && npx prisma migrate deploy && npm run dev

flutter run --dart-define=CANLIFAL_API_URL=http://127.0.0.1:3000/api/v1
```

### Üretim API

Varsayılan: `https://canlifal.com/api` — ek kurulum gerekmez.

### Dikkat

- Firebase dosyaları (`google-services.json`) repoda yok; uygulama bunları try/catch ile tolere eder
- `api/node_modules/` commit edilmez; güncelleme betiği `npm ci` çalıştırır
- Android/iOS platform klasörleri repoda mevcuttur; `flutter create` yeniden çalıştırmayın
