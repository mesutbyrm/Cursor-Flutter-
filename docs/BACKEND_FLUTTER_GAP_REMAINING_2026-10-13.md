# Backend ↔ Flutter — kalan 6 yol (2026-10-13)

Kaynak: `python3 scripts/backend-route-parity.py canlifal-backend/nextjs_space --used-only` @ **591477e1**  
Flutter: **1.0.782+838** — mobil tarafta yapılacak iş **bitti**; aşağıdakiler **canlifal (Next.js) veya games API** deploy’u.

| # | Yol | Öneri |
|---|-----|--------|
| 1 | `GET /api/social-accounts` | Backend: site sosyal link API |
| 2 | `GET/PUT /api/admin/social-accounts` | Backend: admin CRUD (mobil sayfa hazır, 404 mesajı var) |
| 3 | `GET /api/pk/me/history` | Games veya ana site PK geçmiş ucu |
| 4 | `GET /api/pk/me/stats` | Aynı |
| 5 | `GET /api/pk/stats/:userId` | Aynı |
| 6 | `POST /api/notifications/test-push` | Ops/test (mobil diagnostik 404 açıklaması var) |

**Doğrulama:** `main` merge sonrası `bash scripts/wait-apk-build.sh 900` · cihaz: ajans davet (username), hediye SSE (outbox).
