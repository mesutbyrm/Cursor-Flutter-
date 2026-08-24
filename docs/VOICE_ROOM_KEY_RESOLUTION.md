# Sesli oda anahtarı çözümleme (route → API / SSE)

**Tarih:** 2026-08-18  
**Kod:** `mobile/lib/features/voice_hub/presentation/utils/voice_room_key_resolver.dart`  
**Sürüm:** `1.0.264+` (önek), `1.0.265+` (SSE katalog bekleme)

---

## Özet

Canlifal sesli odalarında **aynı oda** için birden fazla route anahtarı kullanılabilir:

| Anahtar türü | Örnek | REST (`song-request`, `messages`) | SSE (`…/stream`) |
|--------------|-------|-----------------------------------|------------------|
| Tam Prisma cuid | `cmoohrbrx00a4nt08zlkdjyil` | ✅ | ✅ |
| Kısmi cuid öneği | `cmoohrbr` | ✅ | ❌ `Room not found` |
| Slug | `canlfal-` | ✅ (bazı uçlar) | Tam cuid gerekli |

Flutter **SSE aboneliğini** her zaman tam cuid ile açar; route kısmi ise oda listesinden çözümler.

---

## Üretim örneği: `cmoohrbr`

| Alan | Değer |
|------|--------|
| Route / paylaşım linki | `cmoohrbr` |
| Tam id | `cmoohrbrx00a4nt08zlkdjyil` |
| Slug (liste) | `canlfal-` |
| Ad | CanlıFal |

Probe: `MUSIC_PROBE_ROOM=cmoohrbr bash scripts/probe-music-room.sh`  
Yakalama: `docs/M7_MUSIC_SSE_CAPTURE.md`

---

## Flutter akışı

1. `VoiceRoomKeyResolver.resolveFromKnownRooms` — `voiceRoomsProvider` listesinde önek/slug eşleşmesi
2. `voiceRoomByIdProvider` / `fetchVoiceRoomById` — derin bağlantı yükleme
3. `_canonicalRoomKey` — SSE `connect(roomId: …)`
4. Girişte `_ensureRoomsCatalogForCanonicalKey` — liste yüklenene kadar bekle (max 10s)
5. `_maybeUpgradeSseRoomKey` — kısmi anahtarla bağlandıysa tam cuid'ye geç
6. `syncSseRoomKeyFromCatalog` — oda listesi geç güncellenirse (RTC sayfa listener)

---

## Test

```bash
cd mobile && flutter test test/features/voice_hub/voice_room_key_resolver_test.dart
```

---

## Backend isteği (opsiyonel)

SSE'nin kısmi cuid önekini kabul etmesi veya `GET /api/chat/rooms/{partialId}` ile tam id döndürmesi tutarlılığı artırır. Şu an Flutter tarafı çözümlüyor.
