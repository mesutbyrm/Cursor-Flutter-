# Canlifal — REST API

Web sitesi ve Flutter uygulaması **aynı PostgreSQL veritabanını** kullanır. Bu depo, **Node.js + Express + Prisma** ile yazılmış JSON REST API ve Prisma şemasını içerir.

## Özellikler

- **JWT**: kısa ömürlü access token + veritabanında izlenen refresh token (döndürme ile yenileme)
- **Tüm kullanıcı işlemleri API üzerinden**: kayıt, giriş, profil, şifre / görünen ad güncelleme, hesap silme, çıkış
- **Standart JSON yanıtı**: `{ "success": true, "data": ... }` veya `{ "success": false, "error": { "code", "message", "details?" } }`

## Hızlı başlangıç

```bash
cd /workspace
docker compose up -d
cp api/.env.example api/.env
cd api
npm install
npx prisma migrate dev --name init
npm run dev
```

Sağlık kontrolü: `GET http://localhost:3000/api/v1/health`

## Flutter entegrasyonu

1. `accessToken` değerini güvenli depoda saklayın (ör. `flutter_secure_storage`).
2. `refreshToken` değerini aynı şekilde saklayın.
3. Korumalı isteklerde başlık: `Authorization: Bearer <accessToken>`
4. Access süresi dolduğunda: `POST /api/v1/auth/refresh` gövdesi `{ "refreshToken": "..." }` — yanıtta yeni çift jeton döner; eski refresh geçersiz kalır.

## API uç noktaları (`/api/v1`)

| Yöntem | Yol | Auth | Açıklama |
|--------|-----|------|----------|
| GET | `/health` | Hayır | Servis ayakta |
| POST | `/auth/register` | Hayır | `{ email, password, displayName? }` |
| POST | `/auth/login` | Hayır | `{ email, password }` |
| POST | `/auth/refresh` | Hayır | `{ refreshToken }` |
| POST | `/auth/logout` | Hayır | İsteğe bağlı `{ refreshToken? }` — verilen oturumu düşürür |
| POST | `/auth/logout-all` | Bearer | Tüm cihaz refresh oturumlarını siler |
| GET | `/users/me` | Bearer | Profil |
| PATCH | `/users/me` | Bearer | `{ displayName?, currentPassword?, newPassword? }` — şifre için ikisi birlikte |
| DELETE | `/users/me` | Bearer | `{ password }` — hesabı kalıcı sil |

## Web sitesi ile paylaşılan veritabanı

Prisma şeması `api/prisma/schema.prisma` içindedir. Web uygulamanız farklı bir dilde ise, **aynı tablo yapısını** (`User`, `RefreshToken`) ve `passwordHash` için **bcrypt** uyumluluğunu koruyun veya web tarafını bu API’ye yönlendirin.

## Üretim notları

- `JWT_ACCESS_SECRET` ve `JWT_REFRESH_SECRET` değerlerini güçlü ve birbirinden farklı tutun.
- HTTPS ve `CORS_ORIGIN` kısıtlaması kullanın.
- İsterseniz periyodik olarak süresi dolmuş `RefreshToken` kayıtlarını temizleyen bir cron ekleyin.
