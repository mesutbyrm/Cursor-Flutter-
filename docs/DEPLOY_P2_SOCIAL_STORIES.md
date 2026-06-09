# P2 — Sosyal Hikâyeler

Parite raporu **#7**.

## Durum

| Endpoint | Prod | Flutter |
|----------|------|---------|
| `GET /api/stories` | ✅ 200 | Birincil (`ApiEndpoints.feed`) |
| `GET /api/social/stories` | ❌ 404 | Yedek (boş dönerse denenir) |

## Sonuç

Deploy gerekmez. Flutter zaten doğru sırayı kullanıyor (`social_remote_datasource.dart` → `fetchStoryRings`).

Web reposunda yalnızca `/api/stories` yolunu koruyun; `/api/social/stories` alias’ı opsiyoneldir.
