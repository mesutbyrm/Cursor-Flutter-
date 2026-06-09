# P2 — Ana Sayfa Fal Kartları

Parite raporu **#6**.

## Durum

| Katman | Durum |
|--------|--------|
| API | ✅ `GET /api/homepage-fortune-cards` → `{ cards: [...] }` |
| Flutter | ✅ `homeFortuneCardsProvider` + `HomeFortuneGrid` (API + `FortuneCatalog` yedek) |

Deploy gerekmez; API zaten prod’da çalışıyor.

## Yanıt örneği

```json
{
  "cards": [
    {
      "id": "cmok...",
      "name": "Kahve Falı",
      "icon": "☕",
      "image": "https://cdn.../kahve.png",
      "href": "/fallar/kahve-fali",
      "isActive": true,
      "sortOrder": 0
    }
  ]
}
```

`href` son segmenti Flutter route slug’ına dönüştürülür (`kahve-fali` → `/fortune/kahve-fali`).
