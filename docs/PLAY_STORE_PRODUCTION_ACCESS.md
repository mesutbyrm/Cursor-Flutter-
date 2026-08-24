# CANLIFAL — PRODUCTION ACCESS PACKAGE

| Alan | Değer |
|------|--------|
| Oluşturulma (UTC) | 2026-08-10 |
| Son doğrulama (UTC) | 2026-08-10 15:14 |
| Code freeze | **ACTIVE** |
| Release candidate commit | `6131504ca927ba320b79f65075ffbebb6009582c` |

> **Kural:** Play Console'dan doğrulanmayan değerler `NOT VERIFIED — PLAY CONSOLE REQUIRED` olarak işaretlenmiştir. Tester sayısı, test süresi, eligibility veya başarı oranı **uydurulmamıştır**.

---

## RELEASE

| Alan | Değer |
|------|--------|
| **Commit** | `6131504ca927ba320b79f65075ffbebb6009582c` |
| **Branch** | `main` |
| **Version** | `1.0.146` |
| **Version Code** | `180` |
| **AAB** | `mobile/build/app/outputs/bundle/release/app-release.aab` |
| **AAB SHA256** | `b3e6832514c573b1c815ce1e3594a6f45b25ab1e33462a04919700aed7776c7f` |
| **AAB build date** | 2026-08-10 14:47:04 UTC |
| **applicationId** | `com.mesutbyrm.canlifal` |
| **Production API** | `https://canlifal.com` (**PASS** — `Env.apiBaseUrl` default) |
| **Release signing** | **FAIL** — `CN=Android Debug`; `mobile/android/key.properties` yok |

**Immutability:** Production Access başvurusu bu commit ve AAB SHA256 üzerinden yapılmalıdır. Başvuru sonrası gereksiz yeni build üretilmemelidir. **Not:** Mevcut AAB debug imzalıdır; Play'e yüklenmeden önce release keystore ile aynı commit'ten yeniden imzalanmış AAB gerekir (yeni SHA256 kaydedilmeli).

---

## CLOSED TEST

| Alan | Değer |
|------|--------|
| **Status** | **BLOCKED** — release-signed AAB Play Console'a yüklenemedi |
| **Test track** | CLOSED TEST *(hedef)* |
| **Release (uploaded)** | NOT VERIFIED — PLAY CONSOLE |
| **Start** | NOT VERIFIED — PLAY CONSOLE |
| **End** | NOT VERIFIED — PLAY CONSOLE |
| **Testers invited** | NOT VERIFIED — PLAY CONSOLE |
| **Testers opted-in** | NOT VERIFIED — PLAY CONSOLE |
| **Active testers** | NOT VERIFIED — PLAY CONSOLE |
| **Test status** | **BLOCKED** (workspace kanıtı: AAB yüklenemedi) |
| **Production access eligibility** | NOT VERIFIED — PLAY CONSOLE |

Closed test **başlamadı**. Bu repoda closed-test tester feedback dosyası yok.

---

## TESTED FEATURES

Son gerçek sonuç (closed-test tester kanıtı yoksa **NOT VERIFIED**). Otomasyon/API notu parantez içinde.

| Feature | Durum |
|---------|-------|
| AUTH | **NOT VERIFIED** *(API login/refresh smoke: PARTIAL)* |
| TRTC | **NOT VERIFIED** *(token API: PARTIAL)* |
| LIVE | **NOT VERIFIED** *(create/token API: PARTIAL)* |
| LIVE FALCI | **NOT VERIFIED** *(request/accept API: PARTIAL; HOST kısıtlı)* |
| PK LIVE | **NOT VERIFIED** *(create API smoke: PARTIAL)* |
| PK VOICE | **NOT VERIFIED** *(create API smoke: PARTIAL)* |
| VOICE ROOM | **NOT VERIFIED** *(presence API: PARTIAL)* |
| SEAT | **NOT VERIFIED** *(BLOCKED — cihaz yok)* |
| PRESENCE | **NOT VERIFIED** *(BLOCKED — cihaz yok)* |
| HEARTBEAT | **NOT VERIFIED** *(BLOCKED — cihaz yok)* |
| GIFT/JETON | **NOT VERIFIED** *(500 jeton API txn: PARTIAL; "0 Jeton" tekrarlanmadı)* |
| SSE | **NOT VERIFIED** *(regresyon 20/20 otomasyon: PASS)* |
| MUSIC | **NOT VERIFIED** *(search API: PARTIAL; gerçek ses yok)* |

**Gerçek cihaz:** `adb devices` boş; closed-test tester raporu yok.

---

## BUGS FOUND

### Closed-test tester raporları
*(yok — closed test başlamadı)*

### Önceden dokümante edilmiş operasyonel kısıtlar (tester bug değil)
| ID | Konu | Severity | Durum |
|----|------|----------|-------|
| B-sign | Release AAB debug imzalı | CRITICAL (release) | Açık |
| B-device | Fiziksel cihaz smoke yok | HIGH (validation) | Açık |
| B-host | HOST test hesabı jeton=0, teller pending | HIGH (LIVE FALCI test) | Açık |

---

## BUGS FIXED

Freeze commit öncesi kod düzeltmeleri (cihaz retest bekliyor):

| ID | Fix | Dosya |
|----|-----|-------|
| B04 | Grace reconnect + guest grid local/remote video | `live_broadcast_room_page.dart`, `live_guest_grid.dart` |
| B07 | PK gift poll dispose | `voice_pk_battle_page.dart` |
| B08 | Voice room TRTC onDispose leave | `chat_room_providers.dart` |

Closed-test hotfix: **yok** (tester raporu gelmedi).

---

## OPEN CRITICAL

| # | Açıklama |
|---|----------|
| 1 | **Release signing FAIL** — AAB `CN=Android Debug`; Play upload ve closed test başlatılamaz |

**PRODUCTION ACCESS BLOCKED** — açık CRITICAL release blocker var.

---

## OPEN HIGH

| # | Açıklama |
|---|----------|
| 1 | Gerçek Android cihazda release smoke tamamlanmadı |
| 2 | Closed-test tester kanıtı yok (test başlamadı) |
| 3 | LIVE FALCI test hesabı kısıtlı (HOST jeton=0, teller onayı pending) |

**PRODUCTION ACCESS = BLOCKED** (açık CRITICAL + HIGH var)

---

## OPEN MEDIUM

*(Closed-test tester raporu yok — açık MEDIUM bug yok)*

Production blocker değil; backlog için tester feedback bekleniyor.

---

## OPEN LOW

*(Closed-test tester raporu yok — açık LOW bug yok)*

Production blocker değil.

---

## REGRESSION (korunan — bozulmadı)

| Suite | Sonuç |
|-------|-------|
| Fortune | 8/8 |
| API | 17/17 |
| P0 | 25/25 |
| Stage 8 | 9/9 |
| Release Gate | 11/11 |
| SSE | 20/20 |
| `flutter test` (freeze build) | 405 pass, 2 skip |

---

## PLAY STORE REQUIREMENTS

| Alan | Durum | Not |
|------|-------|-----|
| App name | **READY** | `Canlifal` (`android:label`) |
| Privacy Policy | **READY** | `https://canlifal.com/gizlilik` HTTP 200; uygulama içi `/legal/gizlilik-politikasi` |
| Data Safety | **USER ACTION REQUIRED** | Play Console formu doldurulmalı |
| App Access | **USER ACTION REQUIRED** | Login zorunlu; test hesapları Play Console'a girilmeli |
| Content Rating | **USER ACTION REQUIRED** | IARC anketi |
| Target Audience | **USER ACTION REQUIRED** | |
| Ads declaration | **USER ACTION REQUIRED** | AdMob ödüllü reklam mevcut; production App ID gerekli |
| Financial features | **USER ACTION REQUIRED** | Jeton, hediye, üyelik, harici ödeme (Play Billing yok) |
| Permissions | **USER ACTION REQUIRED** | Kamera, mikrofon, konum, FGS beyanları |
| Short description | **MISSING** | Repoda Play metni yok |
| Full description | **MISSING** | Repoda Play metni yok |
| App icon (512×512 listing) | **USER ACTION REQUIRED** | Launcher var (max 192×192); Play listing asset yok |
| Feature graphic | **MISSING** | |
| Screenshots (phone) | **MISSING** | |
| Screenshots (tablet) | **MISSING** | |
| Closed test track durumu | **NOT VERIFIED** | Play Console erişimi workspace'te yok |

---

## PRODUCTION ACCESS ANSWER DRAFT

> Kısa başvuru taslağı. Sayı, tarih veya oran uydurulmamıştır. `[PLAY CONSOLE'DAN DOLDURULACAK]` alanları yalnızca Play Console gerçek değerleriyle tamamlayın.

**Test edilen özellikler (closed test — hedef kapsam):** Giriş ve profil; canlı yayın ve izleme; TRTC ses/video; sesli oda, koltuk, presence; hediye ve jeton işlemleri; SSE gerçek zamanlı olaylar; canlı falcı seansı; PK; müzik arama, kuyruk ve gerçek ses çalma.

**Closed test durumu (şu an):** Release `1.0.146` (180), commit `6131504ca927ba320b79f65075ffbebb6009582c`, API `https://canlifal.com`. Closed test track'e release-signed AAB henüz yüklenemedi (debug imza). Test başlangıç/bitiş, davetli/opt-in/aktif tester sayıları: **[PLAY CONSOLE'DAN DOLDURULACAK]**.

**Geri bildirim değerlendirmesi:** Tester'lar standart form ile (cihaz, Android sürümü, özellik, adımlar, beklenen/gerçek, kanıt, severity) rapor verir. CRITICAL/HIGH → code freeze geçici kaldırılır, minimum hotfix, versionCode artışı, yeni AAB, etkilenen akış retest. MEDIUM/LOW → production blocker değilse backlog.

**Kritik sorunlar ve düzeltmeler:** Closed-test tester bug'ı **henüz yok** (test başlamadı). Freeze öncesi kod düzeltmeleri (cihaz retest bekliyor): canlı yayın grace reconnect; guest grid video kimliği; PK gift poll dispose; voice room TRTC leave.

**Production hazırlık gerekçesi (yalnızca closed test tamamlandıktan sonra gönderin):** Üretim API, JWT güvenli depolama, Tencent TRTC, otomatik regresyon (Fortune 8/8, API 17/17, P0 25/25, Stage 8 9/9, Release Gate 11/11, SSE 20/20) aynı commit'te geçti. Gerçek cihaz closed testi kritik akışları doğruladı ve açık CRITICAL/HIGH kalmadı. Gizlilik politikası: `https://canlifal.com/gizlilik`. Data Safety, rating, ads, financial ve permissions Play Console'da tamamlandı. Eligibility: **[PLAY CONSOLE'DAN DOLDURULACAK]**.

**Bu paragrafı closed test kanıtı olmadan göndermeyin.**

---

## USER ACTION REQUIRED

### Blocker (sıra önemli)

1. **Release keystore** oluştur → `mobile/android/key.properties` (commit etme; CI secret)
2. Aynı freeze commit'te: `flutter build appbundle --release` → release-signed AAB
3. Play Console → **Testing → Closed testing** → AAB yükle
4. Min. tester davet et → Google şartlarını Play Console'da doğrula
5. Tester'lara test kapsamı + bug rapor formatı gönder
6. Closed test süresini Play Console'da tamamla (eligibility kuralları Console source of truth)
7. Bu dosyadaki `[PLAY CONSOLE: ...]` alanlarını gerçek değerlerle güncelle
8. Tamamlanmamış Play Store alanları: Data Safety, App Access, Content Rating, Target Audience, Ads, Financial, Permissions, store listing, screenshots, feature graphic, 512 icon
9. Production AdMob App ID (şu an test ID manifest'te)
10. App access test hesapları (şifreler yalnızca Play Console'a; source code'a konmaz):
    - VIEWER: `cursor.test.1786235468@mailinator.com`
    - HOST: `cursor.host.1786235468@mailinator.com` (jeton=0, teller pending — LIVE FALCI için ayrı onaylı falcı hesabı gerekebilir)

### Play Console'dan doldurulacak alanlar

| Alan | Durum |
|------|-------|
| TEST START DATE | NOT VERIFIED — PLAY CONSOLE |
| TEST END DATE | NOT VERIFIED — PLAY CONSOLE |
| TESTERS INVITED | NOT VERIFIED — PLAY CONSOLE |
| TESTERS OPTED-IN | NOT VERIFIED — PLAY CONSOLE |
| ACTIVE TESTERS | NOT VERIFIED — PLAY CONSOLE |
| PRODUCTION ACCESS ELIGIBILITY | NOT VERIFIED — PLAY CONSOLE |

---

# FINAL STATUS

| Alan | Durum |
|------|-------|
| **TECHNICAL RELEASE** | **NOT READY** |
| **CLOSED TEST** | **NOT READY** |
| **PLAY STORE REQUIREMENTS** | **USER ACTION REQUIRED** |
| **PRODUCTION ACCESS** | **BLOCKED** |

**CRITICAL BLOCKERS:**
- Release signing FAIL — AAB `CN=Android Debug`; `key.properties` yok; Play upload mümkün değil
- Closed test başlamadı — workspace'te tester kanıtı yok

**USER ACTION REQUIRED:**
1. Release keystore + `key.properties` → release-signed AAB (aynı freeze commit)
2. Play Console closed testing → AAB yükle → tester davet
3. Closed test süresini ve eligibility'yi Play Console'da tamamla
4. Bu dosyadaki `NOT VERIFIED — PLAY CONSOLE` alanlarını gerçek değerlerle güncelle
5. Data Safety, App Access, Content Rating, Target Audience, Ads, Financial, Permissions
6. Store listing: short/full description, 512 icon, feature graphic, phone/tablet screenshots
7. Production AdMob App ID (manifest'te test ID)
8. App access test hesapları Play Console'a (şifre source code'a konmaz)

**Production Access başvurusu şu an yapılmamalı.**

---

*Code freeze active. Son doğrulama: 2026-08-10 15:14 UTC. Commit/AAB SHA256 değişmedi. Kod değiştirilmedi.*
