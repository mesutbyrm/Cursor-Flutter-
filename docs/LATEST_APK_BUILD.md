# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.711+764` |
| Tarih (UTC) | 2026-10-04 21:22 |
| Commit | [`b84b24151bf2a1fbda4a3be2dd5f5951d7a6013c`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/b84b24151bf2a1fbda4a3be2dd5f5951d7a6013c) |
| İş akışı | [Run 37234451364](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37234451364) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.711+764 (2026-10-04) — Canlı PK düzeltmeleri · sesli oda koltuk/hediye/arka plan

- **Canlı PK — kök neden:** uygulama PK durumunu eski `/api/live/pk` ucundan okuyordu (süre/bitiş/kazanan/taraf yok); kanonik `/api/video-streams/pk` yanıtı atılıyordu. Artık `endsAt`, `serverNow`, `winnerId`, `endedAt`, `stream1Id/stream2Id`, oyuncu adları buradan alınır → puanlar doğru tarafa işlenir, rakip taraf yanlış «sol» sayılmaz
- **Geri sayım:** iki yayıncının cihaz saatinden bağımsız, sunucu saatiyle (`serverNow`) aynı saniyede akar; çift saat düzeltmesi kaldırıldı. Aktif PK'da skor 3–4 sn'de bir de yoklanır
- **Kazanan:** sonuç ekranında herkese «🏆 X kazandı!» yazılır, sonuç ~5,5 sn görünür; erken «PK bitir» ile sunucunun bitirdiği maç artık istemcide «aktif» kalmaz
- **PK sonrası ses/görüntü/kapatma:** rakip odaya köprü PK biter bitmez kesilir (karşı yayıncının sesi gelmeye devam etmiyordu); kendi odaya dönüş yeniden denenir, yerel önizleme yeniden kurulur, 10 sn güvenlik zamanlayıcısı eklendi
- **Hediye bildirimleri:** PK panelinde üst düğmelerin arkasında kalıyordu → sol-ortaya alındı; bildirimler 5 sn sonra kaybolur (altta takılı kalmaz)
- **Sesli oda:** koltuklar küçüldü, oda sahibinde kanat yok (yalnızca 👑); hediye bildirimi 5 sn sonra kaybolur, kalıcı «ilk destekçi» rozeti tam sayfadan kaldırıldı; «Daha Fazla → Oda arka planı» sahip/yönetici için görünür (hazır sunucu görselleri veya yükle)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
