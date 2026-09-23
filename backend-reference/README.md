# Backend Reference — Abacus.ai

Bu klasör Abacus.ai backend entegrasyon paketinin referans alanıdır.

KURALLAR:

1. Bu klasör Flutter kaynak kodu değildir.
2. Bu klasördeki backend referans dosyaları değiştirilmez.
3. Flutter kodu bu referanslara göre entegre edilir.
4. Dokümanda bulunmayan endpoint, URL, request/response modeli,
   authentication yöntemi, WebSocket/SSE olayı veya davranış UYDURULMAZ.
5. downloads/ klasöründeki eski dosyalar kaynak olarak kullanılmaz.
6. Legacy olarak belirtilen belgeler kullanılmaz.
7. Mevcut Flutter özellikleri gereksiz yere değiştirilmez.
8. Mevcut çalışan kod silinmez.

Kaynak: Abacus.ai Flutter entegrasyon paketi.

## GitHub `mesutbyrm/canlifal` — `full-source` dalı

Özel depo bu ortamdan klonlanamaz; mobil hizalama **`backend-reference/canlifal_flutter_paketi/`** ile yapılır:

- `kaynak/lib/pk-state.ts` — `stream1Id/stream2Id` sesli odada `roomId`
- `kaynak/lib/voice-room-events.ts` — SSE `room_event` → `pk_invite` / `pk_requested`
- `BOLUM22_MULTIGUEST_PK_GIFTBOX.md`, `voice_room_api.md`, `canlifal_pk_flutter.zip` → `PK_ENTEGRASYON.md`

Üretim uçları değiştirilmez: sesli PK `POST/GET /api/chat/rooms/{roomId}/pk`, adaylar `GET /api/chat/rooms/pk/candidates?roomId=`, davet poll `GET /api/pk/me/invites?direction=incoming`.

## İlişkili kanonik dosyalar (repoda)

| Amaç | Yol |
|------|-----|
| OpenAPI JSON (betikler) | `backend-docs/openapi.json` |
| Mobil entegrasyon kılavuzu | `docs/FLUTTER_ENTegrasyon_KILAVUZU.md` |
| Yerleşim / duplicate politikası | `docs/BACKEND_INTEGRATION_LAYOUT.md` |
