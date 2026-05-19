# Canlifal REST API

JWT tabanlı kullanıcı API'si. Web sitesi ve Flutter mobil uygulama **aynı MySQL `users` tablosunu** kullanır.

**Base URL:** `http://localhost:3000/api/v1`

## JSON formatı

Başarılı yanıt:

```json
{
  "success": true,
  "data": { },
  "message": "İsteğe bağlı mesaj"
}
```

Hata yanıtı:

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Açıklama",
    "details": {}
  }
}
```

## Kimlik doğrulama

Korumalı uç noktalarda header:

```
Authorization: Bearer <access_token>
```

| Kod | Açıklama |
|-----|----------|
| `VALIDATION_ERROR` | Geçersiz istek gövdesi |
| `UNAUTHORIZED` | Token yok / geçersiz |
| `FORBIDDEN` | Hesap devre dışı |
| `NOT_FOUND` | Kaynak yok |
| `CONFLICT` | E-posta zaten kayıtlı |

---

## Auth

### `POST /auth/register`

Kayıt ol.

**Body:**
```json
{
  "email": "kullanici@ornek.com",
  "password": "sifre1234",
  "name": "Ad Soyad",
  "phone": "+905551234567"
}
```

**Response `201`:**
```json
{
  "success": true,
  "data": {
    "user": { "id": 1, "uuid": "...", "email": "...", "name": "..." },
    "tokens": {
      "accessToken": "...",
      "refreshToken": "...",
      "tokenType": "Bearer"
    }
  },
  "message": "Kayıt başarılı."
}
```

### `POST /auth/login`

Giriş.

**Body:** `{ "email", "password" }`

### `POST /auth/refresh`

Access token yenile.

**Body:** `{ "refreshToken": "..." }`

### `POST /auth/logout` 🔒

Refresh token iptal.

### `POST /auth/forgot-password`

Şifre sıfırlama talebi. Güvenlik için her zaman aynı mesaj döner. `NODE_ENV=development` iken yanıtta `devResetToken` dönebilir.

**Body:** `{ "email" }`

### `POST /auth/reset-password`

**Body:** `{ "token", "password" }`

---

## Kullanıcı 🔒

### `GET /users/me`

Oturum açmış kullanıcı profili.

### `PUT /users/profile`

**Body (hepsi opsiyonel):**
```json
{
  "name": "Yeni Ad",
  "phone": "+905551234567",
  "avatarUrl": "https://cdn.example/avatar.jpg"
}
```

### `PUT /users/password`

**Body:** `{ "currentPassword", "newPassword" }` — tüm oturumlar iptal edilir.

### `POST /users/verify-email`

`emailVerifiedAt` alanını günceller (e-posta servisi entegrasyonu sonrası webhook ile de çağrılabilir).

### `DELETE /users/account`

**Body:** `{ "password" }`

---

## Sağlık

### `GET /health`

```json
{ "success": true, "data": { "status": "ok", "timestamp": "..." } }
```

---

## Flutter örneği

```dart
final response = await http.post(
  Uri.parse('$baseUrl/api/v1/auth/login'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({'email': email, 'password': password}),
);
final json = jsonDecode(response.body);
if (json['success'] == true) {
  final access = json['data']['tokens']['accessToken'];
  // Sonraki istekler: Authorization: Bearer $access
}
```

## Web sitesi entegrasyonu

Mevcut PHP/Laravel/Node web siteniz aynı `DATABASE_URL` ile bu tabloyu kullanabilir. Web oturumları için session, mobil için bu API + JWT önerilir; her iki istemci de `users` satırlarını paylaşır.
