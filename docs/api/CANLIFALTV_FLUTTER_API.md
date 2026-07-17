# 📱 CanlifalTV Flutter Mobil Uygulama — API Dokümantasyonu

**Temel API URL:** `https://canlifal.com`  
**İçerik tipi:** `application/json`  
**Son güncelleme (repo):** 2026-07-17  
**Flutter parite:** [`CANLIFALTV_FLUTTER_PARITY.md`](CANLIFALTV_FLUTTER_PARITY.md)

> Tam endpoint gövdeleri ve örnek yanıtlar kullanıcı tarafından sağlanan Mayıs 2026 sürümünden alınmıştır. Üretimde çelişki olursa `docs/FLUTTER_ENTegrasyon_KILAVUZU.md` geçerlidir.

---

## 📋 İçindekiler

1. [Kimlik Doğrulama (Auth)](#1-kimlik-doğrulama-auth)
2. [Token/JWT Sistemi](#2-tokenjwt-sistemi)
3. [Kullanıcı Profili](#3-kullanıcı-profili)
4. [Sosyal Akış (Feed)](#4-sosyal-akış-feed)
5. [Hikayeler (Stories)](#5-hikayeler-stories)
6. [Canlı Yayın (Video Streams)](#6-canlı-yayın-video-streams)
7. [Sesli Sohbet Odaları](#7-sesli-sohbet-odaları)
8. [Mesajlaşma (DM)](#8-mesajlaşma-dm)
9. [Bildirimler](#9-bildirimler)
10. [Hediye Sistemi](#10-hediye-sistemi)
11. [Jeton & CFC Bakiyesi](#11-jeton--cfc-bakiyesi)
12. [Gold Üyelik](#12-gold-üyelik)
13. [FunClub](#13-funclub)
14. [Davet (Referral) Sistemi](#14-davet-referral-sistemi)
15. [Trend / Keşfet / Arama](#15-trend--keşfet--arama)
16. [Oyunlar](#16-oyunlar)
17. [12 Fal/Yorum Türü](#17-12-falyorum-türü)
18. [Tencent RTC Entegrasyonu](#18-tencent-rtc-entegrasyonu)
19. [Dosya Yükleme](#19-dosya-yükleme)
20. [Diğer Endpoint'ler](#20-diğer-endpointler)

---

## 1. Kimlik Doğrulama (Auth)

| Metod | Path | Flutter |
|-------|------|---------|
| POST | `/api/auth/mobile-login` | `AuthService.login` |
| POST | `/api/auth/mobile-register` | `AuthService.register` |
| POST | `/api/auth/mobile-refresh` | `dio_provider` 401 refresh |
| — | Logout (istemci token sil) | `AuthService.logout` |

---

## 2. Token/JWT Sistemi

- Header: `Authorization: Bearer <accessToken>`
- Access: 7 gün · Refresh: 30 gün
- Depolama: `flutter_secure_storage`

---

## 3. Kullanıcı Profili

| Metod | Path |
|-------|------|
| GET | `/api/user/profile` |
| PUT | `/api/user/profile` |
| GET | `/api/users/{userId}` |
| GET | `/api/user/followers` |
| GET | `/api/user/following` |
| POST/DELETE | `/api/user/{userId}/follow` |
| GET | `/api/user/{userId}/follow-status` |
| GET | `/api/users/search?q=` |
| GET | `/api/user/credits` |

---

## 4. Sosyal Akış (Feed)

| Metod | Path |
|-------|------|
| GET | `/api/social/posts` |
| POST | `/api/social/posts` |
| POST | `/api/social/posts/{id}/likes` |
| POST/GET | `/api/social/posts/{id}/comments` |

---

## 5. Hikayeler (Stories)

| Metod | Path |
|-------|------|
| GET | `/api/stories` |
| POST | `/api/stories` |

---

## 6. Canlı Yayın (Video Streams)

| Metod | Path |
|-------|------|
| GET | `/api/video-streams` |
| POST | `/api/video-streams` |
| GET | `/api/video-streams/{id}` |
| POST | `/api/video-streams/{id}/join` |
| DELETE | `/api/video-streams/{id}/join` |
| POST | `/api/video-streams/{id}/comments` |
| POST | `/api/video-streams/{id}/like` |
| POST | `/api/video-streams/{id}/gifts` |
| PATCH | `/api/video-streams/{id}` (`status: ended`) |
| GET/POST | `/api/video-streams/pk/*` |
| POST/GET | `/api/video-streams/{id}/co-broadcast` |

**Birleşik live API (7 saha):** `/api/live/*` — bkz. `docs/api/field/README.md`

---

## 7. Sesli Sohbet Odaları

| Metod | Path |
|-------|------|
| GET | `/api/chat/rooms` |
| POST | `/api/chat/rooms/create` |
| GET/POST | `/api/chat/rooms/{id}/messages` |
| POST | `/api/chat/rooms/{id}/presence` |
| GET/POST | `/api/chat/rooms/{id}/seats` |
| POST | `/api/chat/rooms/{id}/voice` |
| POST | `/api/chat/rooms/{id}/gifts` |
| POST | `/api/chat/rooms/{id}/moderation` |

---

## 8–20. Diğer bölümler

Özet endpoint listesi parite tablosunda: [`CANLIFALTV_FLUTTER_PARITY.md`](CANLIFALTV_FLUTTER_PARITY.md)

**18 TRTC:** `POST /api/trtc/token` (önerilen), `POST /api/trtc/usersig` (yedek)

**Polling tablosu (doküman):** SSE birincil olduğunda yedek aralıklar; mobil SSE: kılavuz §5.

---

## 🔒 Güvenlik

- TRTC secret, JWT secret mobilde **olmamalı**
- Token: Secure Storage
- 401 → refresh → login

---

*CanlifalTV Flutter ekibi — repo entegrasyonu 1.0.44+62*
