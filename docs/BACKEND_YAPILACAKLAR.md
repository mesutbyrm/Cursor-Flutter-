# Backend yapılacaklar (mesutbyrm/canlifal)

> **Bu repo mobil istemcidir** — aşağıdaki maddeler **yalnızca** `mesutbyrm/canlifal` reposunda ele alınmalıdır.  
> **Kaynak denetim:** [`BACKEND_FRONTEND_UYUMLULUK.md`](BACKEND_FRONTEND_UYUMLULUK.md) (2026-09-30)

---

## P0 — PK kullanıcı geçmişi uçları (Kategori A)

Flutter `ApiBackendRouter` şu path'leri **ana site** (`canlifal.com`) olarak çözüyor; snapshot'ta **route dosyası yok**:

| Path | Flutter kullanımı | Öneri |
|------|-------------------|--------|
| `GET /api/pk/me/history` | PK geçmiş ekranı / `pk_room_models` | Ana sitede route ekle **veya** resmi games backend path dokümante et + router güncellemesi (mobil ayrı PR) |
| `GET /api/pk/me/stats` | PK istatistik | Aynı |
| `GET /api/pk/me/matches` | PK maç listesi | Aynı |

**Kabul:** Flutter aynı path'e istek atınca 200 + beklenen JSON (kılavuzdaki alan adları) veya router bilinçli olarak games URL'ine yönlendirilir.

---

## P2 — Video PK / TRTC (cihaz şikayetleri)

Aşağıdakiler bu turda **kod karşılaştırmasıyla kanıtlanmadı**; cihazda “karşılıklı görüntü yok” devam ederse backend + token uçları incelenmeli:

- `POST /api/trtc/token` — oda/stream id, role, süre
- `POST /api/video-streams/{id}/join` — misafir/co-broadcast sonrası layout

*(Mobil taraf: token isteği kılavuz §9 ile hizalı; backend yanıt alanları değişirse mobil model güncellenir.)*

---

## Not

- Sesli oda PK, presence, canlı misafir daveti: **2026-09-30** denetiminde Flutter tarafı uyumlu veya Flutter düzeltmesi yapıldı.  
- Yeni backend route eklendiğinde `scripts/generate_backend_frontend_uyumluluk_report.py` yeniden çalıştırılmalı.
