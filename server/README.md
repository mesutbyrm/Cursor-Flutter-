# Canlifal API

REST backend for the Canlifal live fortune-telling mobile app.

## Quick start

```bash
cd server
cp .env.example .env
npm install
npm start
```

Server runs at `http://localhost:3000` by default.

## Endpoints

### `POST /api/login`

Authenticate with email and password.

**Body**

```json
{
  "email": "user@example.com",
  "password": "secret123"
}
```

**Response** `200`

```json
{
  "success": true,
  "token": "<jwt>",
  "user": { "id": 1, "username": "...", "email": "...", "displayName": "...", "avatarUrl": null, "createdAt": "..." }
}
```

### `POST /api/register`

Create an account.

**Body**

```json
{
  "username": "melek",
  "email": "melek@example.com",
  "password": "secret123",
  "displayName": "Melek"
}
```

`displayName` is optional.

**Response** `201` — same shape as login.

### `GET /api/profile`

Return the authenticated user. Requires header:

`Authorization: Bearer <token>`

**Response** `200`

```json
{
  "success": true,
  "user": { ... }
}
```

### `GET /api/live-streams`

List active live streams (seeded on first run).

Optional query: `?live=false` to include offline streams.

**Response** `200`

```json
{
  "success": true,
  "count": 4,
  "streams": [
    {
      "id": 1,
      "title": "Kahve Falı — Canlı Yorum",
      "streamerName": "Ayşe Hanım",
      "category": "kahve",
      "thumbnailUrl": null,
      "streamUrl": null,
      "isLive": true,
      "viewerCount": 128,
      "startedAt": "..."
    }
  ]
}
```

### `POST /api/send-message`

Post a chat message to a live stream. Requires authentication.

**Body**

```json
{
  "streamId": 1,
  "message": "Merhaba!"
}
```

**Response** `201`

```json
{
  "success": true,
  "message": {
    "id": 1,
    "streamId": 1,
    "userId": 1,
    "username": "melek",
    "content": "Merhaba!",
    "createdAt": "..."
  }
}
```

## Environment

| Variable        | Default              | Description        |
|----------------|----------------------|--------------------|
| `PORT`         | `3000`               | HTTP port          |
| `JWT_SECRET`   | dev fallback         | JWT signing secret |
| `DATABASE_PATH`| `./data/canlifal.db` | SQLite file path   |
