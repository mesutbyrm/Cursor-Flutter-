# Backend ↔ Flutter entegrasyon denetimi (2026-09-28)

> **Kaynak:** `backend-reference/canlifal_flutter_paketi/`, `backend-docs/`, `docs/FLUTTER_ENTegrasyon_KILAVUZU.md`, `docs/BACKEND_DOCS_ESLESME.md`.  
> **`mesutbyrm/canlifal` `full-source`:** bu ortamda clone erişilemedi; mirror kullanıldı.

## Özet

Flutter **1.0.630+681** ile üretim sözleşmesi büyük ölçüde hizalı (JWT, presence, PATCH seats, SSE, TRTC, oda hediyeleri). Kritik kalan alanlar: hayalet presence (backend penceresi), sesli PK games host + respond path, istemci `POST /api/live/pk/score`, `full-source` route parity teyidi.

## Kritik bulgular

| Konu | Not |
|------|-----|
| Hayalet presence | Backend SSE ~5 dk penceresi; mobil çıkış/heartbeat doğru — sunucu penceresi kısaltılmalı |
| Sesli PK | REST games backend; ana site GET stub; `ApiBackendRouter` zorunlu |
| PK accept/reject | Parite dokümanı `…/pk/{id}/respond`; Flutter `POST …/pk` + action body |
| PK skor | Doküman: skor hediyeden; `pk/score` admin — canlı beğeni `live/pk/score` riski |
| `/join-seat` | Sabit var, kullanılmıyor; auto-seat PATCH seats |

## Düzeltme planı (sıra)

1. Faz 0: `canlifal` clone + `backend-method-parity.py` / iki hesap PK testi  
2. Faz 1: PK respond path, skor POST kaldırma/flag, voice gövde sadeleştirme  
3. Faz 2: games hata yönetimi, hediye `battleId`  
4. Faz 3: backend presence penceresi, PK JSON normalize  

Detay: agent oturumu raporu (2026-09-28) ve `docs/BACKEND_DOCS_ESLESME.md`.
