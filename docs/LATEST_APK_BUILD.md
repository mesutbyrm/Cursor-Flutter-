# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.634+685` |
| Tarih (UTC) | 2026-09-29 13:22 |
| Commit | [`4e46a6e1bea8c42a860aa82d836a8863ce57e922`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/4e46a6e1bea8c42a860aa82d836a8863ce57e922) |
| İş akışı | [Run 36571932822](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/36571932822) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.634+685 (2026-09-29) — Backend sözleşmesine göre SSE, çıkış ve yoklama düzeltmeleri

- **SSE:** parça sınırında bölünen Türkçe karakter/emoji artık olayı bozmuyor (önceden JSON bozulup PK daveti, presence, hediye olayları sessizce kayboluyordu); 6 SSE istemcisinde ortak çözücü
- **Odadan çıkış:** `DELETE /api/chat/rooms/{id}/presence?leave=1` ilk istek — sunucu koltuğu boşaltır, mikrofon oturumunu kapatır, sahip çıkınca PK'yı bitirir ve `user_left` yayınlar (önceden yalnızca `lastSeen` sıfırlanıyor, kullanıcı/koltuk asılı kalıyordu)
- **Hız:** canlı PK davet yoklaması 1 sn → 2 sn ve üst üste binmiyor; yayını olmayan kullanıcıda `/pk/me/invites` 10 sn'de bir; sesli PK davet ve falcı bekleme yoklamalarında istek yığılması engellendi
- Backend değişikliği yok


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
