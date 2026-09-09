# Profil & Admin — Sonraki özellik önerileri

> **Sürüm:** 1.0.417+455 · Üretim API: `https://canlifal.com`

## P1 — Kısa vadede (backend hazır veya küçük mobil iş)

1. **Admin dashboard widget (Android)** — Bekleyen ödeme sayısı + son aktivite; staff ana ekranından tek dokunuşla `/admin`.
2. ~~**Ödeme talebi inline onay**~~ — ✅ `1.0.417+455` swipe + red şablonları
3. ~~**Kullanıcı finans geçmişi filtreleri**~~ — ✅ `1.0.417+455` jeton/CFC chip
4. ~~**Sesli oda admin: katılımcı listesi**~~ — ✅ `1.0.417+455` presence + kick
5. ~~**Yayın admin: izleyici listesi**~~ — ✅ `1.0.417+455` online-users picker
6. **Profil özet: haftalık grafik** — Jeton harcama / kazanç mini sparkline (`/api/me` activity veya wallet history).
7. ~~**Staff görev checklist**~~ — ✅ `1.0.417+455` dashboard günlük görevler
8. **Rol önizleme: canlı test** — “Bu rolle görünüm” toggle (salt UI, backend değişmez).

## P2 — Orta vade (koordinasyon gerekir)

9. **2FA / güvenlik merkezi** — Web NextAuth + mobil `POST /api/auth/*` 2FA uçları netleşince profil güvenlik sekmesi.
10. **Staff QR giriş** — Play/internal test dağıtımı için QR ile staff oturumu (JWT kısa ömür + device binding).
11. **Admin SSE birleştirme** — Ödeme SSE + aktivite feed tek reconnect kanalı (pil dostu).
12. **Profil bölüm sırası** — Accordion sırasını kullanıcı sürükle-bırak ile özelleştirme.
13. **Finans denetim export** — Oda finans audit CSV/PDF paylaşım (share_plus).
14. **Moderasyon SLA rozeti** — 24s içinde işlenmeyen raporlar için kırmızı badge.

## P3 — Büyük / ürün

15. **Tam web admin parity** — Mobil admin’de eksik kalan web-only modüller (reklam, Stripe, envanter) için deep link hub.
16. **Çoklu staff rolü** — Tek kullanıcıda birden fazla rol birleşimi (`StaffAccess` composite).
17. **Profil herkese açık vitrin** — Ziyaretçi modu + gizlilik katmanları (takipçi / herkes).
18. **AI özet: günlük admin digest** — Aktivite feed + ödeme özetini tek paragraf (yalnızca staff).

## Atlanan (bilinçli)

- **2FA, QR staff, home widget** — Backend veya platform işi; mobil-only mock yapılmadı.

---

İncelemek istediğiniz madde numarasını yazın; öncelik sırasına göre bir sonraki sprint’e alalım.
