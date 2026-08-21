# Bildirimler + Mesajlar + Ayarlar + Navigasyon V2

Sürüm: **1.0.330+366**  
Dal: `cursor/notifications-messages-settings-v2-5ac6`

## NOTIFICATIONS

### API

| İşlem | Endpoint | Not |
|-------|----------|-----|
| Liste | `GET /api/notifications` | Pagination client-side (`NotificationsListNotifier.loadMore`) |
| Unread count | `GET /api/notifications/unread` | 404/hata → liste üzerinden fallback |
| Tek okundu | `PATCH /api/notifications` | `{notificationId}` veya `{id, read:true}` |
| Tümünü oku | `POST/PATCH /api/notifications` | `{markAll:true}` vb. |
| Aktivite (profil) | Canlifal user API | `Env.useMobileAuth` ile birleştirilir |

Parse alanları: `id`, `type`, `title`, `body`, `read/isRead`, `createdAt`, `targetPath/deepLink`, `targetId/referenceId`, `imageUrl/avatar`, `senderId`.

### Unread

- `notificationsUnreadApiProvider` → backend count
- `notificationsUnreadCountProvider` → API öncelikli, yoksa listeden hesap
- `UnreadBadgeFormat`: `1–9` sayı, `10–999` → `9+`, `1000+` → `999+`
- Bildirim sayfası açılınca `notificationsUnreadApiProvider` invalidate

### Read

- Tek tıklama: `markNotificationRead()` — optimistic UI, API fail → refresh ile geri al
- Tümünü oku: kullanıcı aksiyonu (`Tümünü oku`); zil ikonuna tıklamada otomatik okuma **yok**

### Deep Link

- `notification_action.dart` — `targetPath` / `deepLink` öncelikli
- Push: `PushNavigationHandler` — oturumsuz → `PostLoginNavigation.remember` + login
- Login sonrası: `PostLoginNavigation.takePending()` → hedef route
- Geçersiz route → `/feed` (crash yok)

---

## MESSAGES

### Conversations

- `GET /api/messages` — `conversationId`, kullanıcı, avatar, `lastMessage`, `lastMessageAt`, `unreadCount`
- Yerel gizleme: `HiddenConversationsStore` (kullanıcı scoped)

### Messages

- `messages()` + optimistic send (`local-*` id)
- `DmMessageDedupe.merge()` — duplicate `messageId` engeli, optimistic reconcile

### Real-time

- Mevcut: SSE (sohbet) + `DmRealtimeListener` 12s poll — **Socket.IO eklenmedi**
- Açık sohbet: `openDmConversationIdProvider` + `refreshOpenDmChat`

### Read

- Konuşma listesi refresh ile unread güncellenir
- Mesaj ekranı açılınca backend read mekanizması mevcut repository üzerinden

### Attachments

- Backend destekliyorsa mevcut upload akışı; desteklenmeyen tipte fake UI **yok**

---

## SETTINGS

| Alan | Durum |
|------|--------|
| Bildirim ayarları | Bildirimler sayfası + OneSignal izin |
| Tema | Mevcut 6 tema + dark/light (`ThemeModeSelector`) |
| Gizlilik toggle | **Yalnızca local** — backend API yok |
| Önbellek temizle | `AppCacheClear.clearNonAuthCaches()` — JWT korunur |
| Çıkış | Tam oturum temizliği |

---

## NAVIGATION

### Routes (mevcut go_router)

`/feed`, `/social`, `/shorts`, `/voice-rooms`, `/live`, `/canli-falcilar`, `/fortune/*`, `/games`, `/profile`, `/wallet`, `/notifications`, `/messages`, `/chat/:id`, `/settings`, `/auth/login`, …

### Guards

- `AuthRedirect.targetFor` — oturumsuz korumalı sayfalar `/feed` veya login builder

### Deep Links

- Push + bildirim listesi → `navigateFromNotification(Async)`
- Pending route login sonrası

### Back

- Mevcut shell + go_router stack — modal/keyboard davranışı korundu

---

## AUTH

### Token / Refresh

- Mevcut JWT + `AuthTokenRefreshCoordinator` — değiştirilmedi

### Logout

`authController.logout()`:

1. OneSignal logout
2. `ApiHttpCache` + `ApiCacheStore` clear
3. `sessionUserCache` clear
4. `invalidateUserSessionCaches(userId)` — bildirim/mesaj/sosyal provider + yerel read/hidden/deleted store
5. Repository logout

---

## CACHE

- Logout: HTTP + API cache + kullanıcı provider invalidation
- Ayarlar: görsel (`PaintingBinding.imageCache`) + API cache; **token silinmez**

---

## PERFORMANCE

- Bildirim listesi lazy pagination
- Duplicate profile push önleme: mevcut router davranışı
- Foreground resume: hafif unread refresh (push lifecycle)

---

## TESTS

```bash
cd mobile && dart analyze
cd mobile && flutter test test/features/messages/dm_message_dedupe_test.dart
cd mobile && flutter test test/core/navigation/unread_badge_format_test.dart
cd mobile && flutter test test/features/notifications/notification_action_test.dart
```

---

## MULTI USER TEST

Manuel senaryo (CI dışı):

1. Kullanıcı A → B'ye mesaj
2. B bildirim + unread badge
3. B sohbeti aç → unread sıfır
4. A logout → B login
5. A'nın mesaj/bildirim/badge/cache B'de görünmemeli

Logout sonrası `invalidateUserSessionCaches` + `HiddenConversationsStore.clearForUser` ile sağlandı.

---

## BACKEND EKSİKLERİ

1. `GET /api/notifications/unread` bazı ortamlarda 404 — rozet liste fallback kullanır
2. Gizlilik ayarları (profil görünürlüğü, çevrimiçi) — backend sync endpoint yok
3. Push bildirim tercihleri (ses/titreşim/kategori) — OneSignal + local; dedicated REST yok
4. DM read receipt tek endpoint belgelenmemiş — konuşma listesi refresh ile senkron

---

## FAKE/HARDCODE DATA

Production UI tarandı — bildirim/mesaj listelerinde fake/mock/dummy veri yok.  
Gizlilik toggle `initial: true` yalnızca local state (backend yok).

---

## DEĞİŞEN DOSYALAR

| Dosya | Değişiklik |
|-------|------------|
| `mobile/lib/core/bootstrap/user_session_cleanup.dart` | Yeni — logout provider invalidation |
| `mobile/lib/core/bootstrap/app_cache_clear.dart` | Yeni — ayarlar önbellek |
| `mobile/lib/core/navigation/post_login_navigation.dart` | Yeni — pending deep link |
| `mobile/lib/core/navigation/unread_badge_format.dart` | Yeni — rozet format |
| `mobile/lib/features/messages/domain/utils/dm_message_dedupe.dart` | Yeni — dedupe |
| `mobile/lib/features/notifications/data/datasources/notifications_remote_datasource.dart` | deepLink, unread API, imageUrl |
| `mobile/lib/features/notifications/presentation/providers/notifications_providers.dart` | unread API, mark one read |
| `mobile/lib/features/notifications/presentation/pages/notifications_page.dart` | avatar, unread tint |
| `mobile/lib/features/home/presentation/widgets/approved/home_header.dart` | zil mark-all kaldırıldı |
| `mobile/lib/features/auth/presentation/providers/auth_providers.dart` | logout cleanup, post-login nav |
| `mobile/lib/core/push/push_navigation_handler.dart` | auth guard, deepLink |
| `mobile/lib/core/push/push_lifecycle_listener.dart` | foreground refresh |
| `mobile/lib/features/profile/presentation/pages/settings_page.dart` | önbellek temizle |
| `mobile/lib/features/messages/presentation/providers/chat_messages_list_notifier.dart` | dedupe merge |
| `mobile/lib/features/messages/data/repositories/messages_repository_impl.dart` | dedupe |
| `mobile/lib/features/messages/data/hidden_conversations_store.dart` | clearForUser |
| `mobile/lib/features/messages/data/deleted_messages_store.dart` | clearForUser |
| `mobile/lib/core/ui/premium/premium_icon_button.dart` | UnreadBadgeFormat |
| `mobile/lib/features/messages/presentation/widgets/conversations_list_sliver.dart` | UnreadBadgeFormat |
| `mobile/lib/features/notifications/domain/notification_action.dart` | targetPath comment/like, fallback |
| `mobile/test/features/messages/dm_message_dedupe_test.dart` | Yeni |
| `mobile/test/core/navigation/unread_badge_format_test.dart` | Yeni |
| `mobile/pubspec.yaml` | 1.0.330+366 |
| `mobile/CHANGELOG.md` | sürüm notu |
