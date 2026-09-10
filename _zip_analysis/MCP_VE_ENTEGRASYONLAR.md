# CanlıFal — MCP ve Dış Entegrasyonlar

## 1. MCP durumu (net cevap)

**Bu uygulama bir MCP (Model Context Protocol) sunucusu yayınlamıyor ve bir MCP istemcisi de barındırmıyor.**
Canlı sistemde MCP üzerinden erişilebilen bir uç nokta yoktur; Flutter uygulamasının MCP’ye ihtiyacı yoktur.

Önceki devir paketinde bir `01_mcp-server/` klasörü bulunuyordu; bu, geliştirme sırasında Cursor/IDE tarafına yardımcı olması için hazırlanmış **yerel bir geliştirici aracıydı**, üretimdeki backend’in parçası değildir. Flutter entegrasyonunda kullanılmaz.

Tüm veri erişimi **HTTP JSON API** (+ SSE) üzerinden yapılır. Kaynak listeler: `ENDPOINTS.md`, `endpoints_index.json`, `postman_collection.json`.

## 2. Kullanılan dış servisler

| Servis | Amaç | Kod |
|---|---|---|
| Tencent TRTC | Canlı ses/görüntü, PK, sesli odalar | `lib/trtc-client.ts`, `lib/trtc-room.ts`, `/api/trtc/*`, `/api/tencent/webhook` |
| OneSignal | Mobil ve web push bildirimi | `lib/onesignal.ts`, `lib/onesignal-admin.ts`, `lib/push.ts` |
| S3 / R2 uyumlu nesne depolama | Görsel, video, hediye animasyonları, avatar | `lib/s3.ts`, `lib/r2-storage.ts`, `lib/aws-config.ts` |
| LLM API | Fal üretimi (akışlı) | `lib/llm.ts`, `/api/fortunes/*` |
| E-posta bildirimi | Hoş geldin, düşük kredi, iletişim formu, fal özeti | `lib/email-service.ts` |
| Google / Apple / TikTok | Sosyal giriş (mobil) | `/api/auth/mobile-google`, `/api/auth/mobile-apple`, `/api/auth/mobile-tiktok` |

Tüm gizli anahtarlar sunucu tarafında ortam değişkeni olarak tutulur; **hiçbiri istemciye gönderilmez**. Flutter yalnızca kendi kullanıcı token’ını taşır.

## 3. Webhook’lar (sunucu-sunucu, mobil ilgilendirmez)

- `POST /api/trtc/webhook`
- `POST /api/tencent/webhook`
