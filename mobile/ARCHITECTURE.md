# Canlifal Mobile — Production Architecture

TikTok × Bigo Live × Discord × Instagram × Twitch kalitesinde Flutter istemci.

## Katmanlar (Clean Architecture)

```
lib/
├── app/                 # MaterialApp, GoRouter
├── core/
│   ├── config/          # Env, API hosts
│   ├── network/         # Dio, cookies, JWT, endpoints
│   ├── theme/           # AppColors, AppTheme, CanlifalTokens
│   ├── ui/premium/      # Reusable premium widgets
│   ├── navigation/      # Page transitions
│   ├── storage/         # Hive local cache
│   └── widgets/         # Shared non-feature widgets
└── features/<feature>/
    ├── data/            # datasources, DTOs, repository impl
    ├── domain/          # entities, repository contracts
    └── presentation/    # pages, providers, widgets
```

## State management

- **Riverpod 2.x** — `Provider`, `FutureProvider`, `AsyncNotifier`
- Auth: `authControllerProvider` → router refresh
- Feature providers: `*RepositoryProvider` → UI

## Navigasyon

- **GoRouter** — `StatefulShellRoute` (5 sekme)
- Premium geçişler: `AppPageTransitions` (fade + slide)

## Gerçek zamanlı

| Özellik | Teknoloji |
|---------|-----------|
| Canlı video | Tencent TRTC (`tencent_rtc_sdk`) |
| Sesli oda | TRTC + Socket.IO (hediye/chat) |
| REST | Dio + canlifal.com API |
| Oturum | Cookie jar + secure storage |

## Veri modelleri (yol haritası)

| Aşama | Araç |
|-------|------|
| Şimdi | Manuel DTO + `json_util` |
| Sonraki | **Freezed** + **json_serializable** (`dart run build_runner build`) |
| Yerel önbellek | **Hive** (`LocalCache`) |

## Firebase (mağaza öncesi)

- `firebase_core`, `firebase_messaging`, `firebase_analytics` — ayrı flavor; `google-services.json` / `GoogleService-Info.plist` gerekir
- Şu an: REST + Socket.IO; push için backend webhook planı ARCHITECTURE altında

## Özellik modülleri

| Modül | Durum |
|-------|--------|
| Auth (login, register, Google SSO) | ✅ |
| Keşfet / feed | ✅ |
| Sosyal + stories | ✅ |
| Canlı yayın + hediyeler | ✅ (TRTC) |
| Sesli odalar | ✅ |
| Profil + jeton | ✅ |
| Mesajlar | ✅ (temel) |
| Bildirimler | ✅ (liste) |
| OTP / şifre sıfırlama | 🔜 API hazır olunca |
| Moderasyon / rapor | 🔜 |
| Freezed DTO migrasyonu | 🔜 |

## Performans kuralları

- `RepaintBoundary` — feed, sosyal liste, canlı liste
- `CachedNetworkImage` + `memCacheWidth`
- Canlı odada `BackdropFilter` sınırlı; shell nav’da yok
- `Timer` / controller → `dispose` zorunlu
- Monolit dosya bölme: `live_broadcast_room` → `widgets/broadcast_room/*`

## UI sistemi

Bkz. `DESIGN_SYSTEM.md` — `AppColors`, `context.tokens`, `core/ui/premium/`.

## CI / sürüm

- GitHub Actions: `flutter analyze` + release APK
- Sürüm: `pubspec.yaml` `version: x.y.z+build`
