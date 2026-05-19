# Canlifal

Canlifal mobil uygulaması ve web sitesi için paylaşımlı veritabanı + REST API.

## Proje yapısı

| Dizin | Açıklama |
|-------|----------|
| `api/` | Node.js REST API (Express, Prisma, JWT) |
| `downloads/` | Test APK dosyası |
| `docs/API.md` | Uç nokta dokümantasyonu |

## Hızlı başlangıç

### 1. MySQL (Docker)

```bash
docker compose up -d mysql
```

### 2. API

```bash
cd api
cp .env.example .env
# .env içinde JWT secret'ları üretin
npm install
npx prisma migrate deploy
npm run dev
```

API: `http://localhost:3000/api/v1`

### 3. Tüm stack (Docker)

```bash
export JWT_ACCESS_SECRET="$(openssl rand -hex 32)"
export JWT_REFRESH_SECRET="$(openssl rand -hex 32)"
docker compose up -d --build
```

## Flutter

Mobil uygulama `docs/API.md` dosyasındaki JSON sözleşmesini kullanır. `Authorization: Bearer` header ile korumalı istekler gönderin; access token süresi dolunca `/auth/refresh` çağırın.

## APK

Test APK: `downloads/canlifal-mobile-release.apk` — ayrıntılar için `APK_DOWNLOAD.md`.
