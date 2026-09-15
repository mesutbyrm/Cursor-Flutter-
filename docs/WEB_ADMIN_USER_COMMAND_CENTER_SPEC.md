# Web Admin — Tek Kullanıcı Yönetim Merkezi (P6)

## Bileşen

`components/admin/UserCommandCenterModal.tsx`

- Props: `userId: string`, `open: boolean`, `onClose`
- Veri: mobil ile aynı uçlar (`GET /api/admin/users/:id/overview`, lazy sekmeler)
- Yetki: `useStaffPermissions()` — backend 403 yedek

## Sekmeler

Özet, Aktivite, Oda, Canlı, Falcı, Jeton, CFC, Hediye, Kazanç, Harcama, Ajans, VIP, Moderasyon, Yetkiler, Geçmiş, Medya, Raporlar

## Global açılış

`AdminUserLink` wrapper — avatar/username tıklanınca modal; admin listelerinde aynı component.

## Deploy

`backend-parity` admin hub route’ları + `scripts/apply-backend-parity-to-nextjs.sh`
