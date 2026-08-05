# Falcı daveti — OneSignal Kabul / Reddet aksiyon düğmeleri

Flutter tarafı hazır: `PsychicPushActionBridge` (`mobile/lib/features/live_psychics/presentation/controllers/psychic_push_action_bridge.dart`) ve `OneSignalBootstrap` tıklama dinleyicisi.

**Sunucu / OneSignal dashboard** aşağıdaki sözleşmeyi göndermelidir.

---

## Zorunlu alanlar (`additionalData`)

| Alan | Örnek | Açıklama |
|------|-------|----------|
| `sessionId` | `cmxxx…` | Falcı oturum kimliği (`POST /api/fortune-tellers/session`) |
| `type` veya `kind` | `psychic_invite` / `fortune_session` | Davet filtresi (opsiyonel ama önerilir) |
| `tellerUserId` | `cmoks76yf…` | Falcı `user.id` — teşhis için |
| `clientName` | `Admin Test` | Bildirim metni |

Alternatif anahtarlar (geri uyum): `session_id`, nested `data.sessionId`.

---

## Aksiyon düğmeleri (Android + iOS)

Her düğmenin **`actionId`** değeri Flutter köprüsünde eşleşmelidir.

### Kabul

| `actionId` (herhangi biri) | API |
|----------------------------|-----|
| `accept` | `POST` falcı oturum kabul |
| `kabul` | aynı |
| `kabul_et` | aynı |
| `psychic_accept` | aynı |

### Reddet

| `actionId` (herhangi biri) | API |
|----------------------------|-----|
| `reject` | `POST` falcı oturum red |
| `reddet` | aynı |
| `psychic_reject` | aynı |

---

## OneSignal REST örneği

```json
{
  "app_id": "<ONESIGNAL_APP_ID>",
  "include_aliases": { "external_id": ["<tellerUserId>"] },
  "target_channel": "push",
  "headings": { "en": "Canlı falcı daveti", "tr": "Canlı falcı daveti" },
  "contents": { "en": "10 dk oturum — Kabul veya Reddet", "tr": "10 dk oturum — Kabul veya Reddet" },
  "data": {
    "sessionId": "cmxxx-session-id",
    "type": "psychic_invite",
    "tellerUserId": "cmoks76yf00c4ph08ppcoqg98",
    "clientName": "Müşteri Adı"
  },
  "buttons": [
    { "id": "psychic_accept", "text": "Kabul", "icon": "ic_menu_accept" },
    { "id": "psychic_reject", "text": "Reddet", "icon": "ic_menu_close_clear_cancel" }
  ],
  "android_channel_id": "psychic_invites",
  "ios_category": "PSYCHIC_INVITE"
}
```

> **Not:** iOS için `UNNotificationCategory` ile aynı `actionId` değerleri tanımlanmalıdır.

---

## Flutter akışı

1. Kullanıcı bildirimde **Kabul** / **Reddet**'e basar veya uygulama açıkken aksiyon gelir.
2. `OneSignal.Notifications.addClickListener` → `PsychicPushActionBridge.handle(actionId:, data:)`.
3. `onRespond` callback (`psychic_incoming_call` / lifecycle) → `POST` kabul veya red endpoint'i.
4. Eşleşme yoksa `PushNavigationHandler` deep link dener.

---

## Doğrulama

1. Falcı cihazında `OneSignalBootstrap.externalUserId` = `user.id`.
2. Dashboard'da push gönder; `actionId` log'da görünmeli.
3. Arka planda basıldığında API çağrısı 200 dönmeli; uygulama açılınca oturum ekranına yönlendirme.

İlgili test belgesi: [`docs/FAZ1_PSYCHIC_PUSH_TEST_PROMPT.md`](FAZ1_PSYCHIC_PUSH_TEST_PROMPT.md).
