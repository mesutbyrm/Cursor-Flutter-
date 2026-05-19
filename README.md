# Canlifal

| Klasör | Açıklama |
|--------|----------|
| [`mobile/`](mobile/) | **Ana Flutter istemcisi** — Clean Architecture, Riverpod, JWT, TikTok tarzı UI (CI/APK bu klasörden derlenir) |
| [`api/`](api/) | İsteğe bağlı yerel JWT REST API (Node.js + Prisma + PostgreSQL) |

Test APK: [`APK_DOWNLOAD.md`](APK_DOWNLOAD.md)

## Hızlı başlangıç (Flutter)

```bash
cd mobile
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=API_BASE_URL=https://canlifal.com
```

Ayrıntılı mimari ve uç noktalar: [`mobile/README.md`](mobile/README.md)

## Yerel JWT API (isteğe bağlı)

```bash
docker compose up -d
cp api/.env.example api/.env
cd api && npm ci && npx prisma migrate deploy && npm run dev
```

```bash
cd mobile
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
```

> Android emülatörde `localhost` yerine `10.0.2.2` kullanın.

## Cursor Cloud ortamı

Güncelleme betiği: `bash scripts/cursor-update.sh` — ayrıntılar [`AGENTS.md`](AGENTS.md)
