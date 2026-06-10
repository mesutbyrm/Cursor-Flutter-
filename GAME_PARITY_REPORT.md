# Oyun Parite Raporu

Tarih: 2026-06-10  
Kapsam: Canlifal.com oyun sistemi ile Flutter uygulaması oyun modülü.

## Web oyun envanteri

Canlifal.com envanterine göre webde oyun sistemi tamamlanmıştır:

- 18+ çok oyunculu oyun:
  - XOX
  - Tombala
  - Tavla
  - Pişti
  - Sayı Tahmin
  - Zar
  - Okey
  - Okey 101
  - Connect 4
  - Reversi
  - Dama
  - Mangala
  - Gomoku
  - Amiral Battı
  - Kelime Düellosu
  - Quiz 1v1
  - Kart Eşleştirme PvP
  - SOS
  - Taş Kağıt Makas
- 15 mini oyun:
  - 2048
  - Anagram
  - Çarkıfelek
  - Renk Sıralama
  - Adam Asmaca
  - Logo Quiz
  - Mastermind
  - Hafıza Eşleştirme
  - Mayın Tarlası
  - Quiz
  - Kazı Kazan
  - Slot
  - Sudoku
  - Kelime Avı
  - Kelime Bulmaca

## Uygulanan Flutter parite paketi

### Oyun listesi

- Flutterda eklendi.
- `GamesHubPage` ile native oyun merkezi oluşturuldu.
- Web API `GET /api/games` okunur.
- API boş veya hatalı dönerse web envanterindeki tüm oyunları kapsayan fallback katalog kullanılır.

Kullanılan dosyalar:

- `mobile/lib/features/games/domain/game_models.dart`
- `mobile/lib/features/games/data/game_remote_datasource.dart`
- `mobile/lib/features/games/presentation/providers/game_providers.dart`
- `mobile/lib/features/games/presentation/pages/games_hub_page.dart`

### Oyun giriş ekranı

- Flutterda eklendi.
- Her oyun kartında:
  - Oda oluştur
  - Otomatik eşleş
  - Mini oyunlarda skor kaydı denemesi
- Oda oluşursa `/games-room/:id` ekranına geçilir.

Kullanılan API'ler:

- `POST /api/games/rooms`
- `POST /api/games/auto-match`
- `POST /api/games/mini-scores`

### Jeton kullanımı

- Flutterda kısmen eklendi.
- Oyun katalog/oda yanıtındaki şu alanlar okunur:
  - `jetonCost`
  - `cost`
  - `entryFee`
- UI kartlarında Jeton bedeli gösterilir.
- Gerçek Jeton düşümü backend tarafından yapılır; yeni API oluşturulmadı.

### Oyun sonuçları

- Flutterda kısmen eklendi.
- Oyun oda ekranında `result`, `winner`, `outcome` alanları okunur ve gösterilir.
- Webde her oyunun hamle payload şekli farklı olduğundan yeni oyun motoru uydurulmadı.
- Genel hamle endpointi mevcut sözleşmeyle çağrılır.

Kullanılan API:

- `POST /api/games/room/{roomId}`

### Skor tabloları

- Flutterda eklendi.
- Oyun merkezinde liderlik, mini skor ve turnuva özetleri gösterilir.

Kullanılan API'ler:

- `POST /api/games/leaderboard`
- `GET /api/games/history`
- `GET /api/games/profile`
- `GET /api/games/mini-scores`
- `GET /api/tournaments`
- `POST /api/tournaments/join`

### Gerçek zamanlı güncellemeler

- Web envanterinde oyunlar için socket event kanıtı yoktur.
- Oyun sistemi HTTP polling tabanlıdır.
- Flutter oyun odası ekranı `GameRoomController` ile her 5 saniyede bir oda state endpointini yeniler.

Kullanılan API:

- `POST /api/games/room/{roomId}`

Kullanılan Socket Eventleri:

- Yok. Web envanterinde oyun socket eventleri listelenmedi.

## Kullanılan API endpointleri

- `GET /api/games`
- `GET /api/games/rooms`
- `POST /api/games/rooms`
- `POST /api/games/room/{roomId}`
- `POST /api/games/room/{roomId}/join`
- `POST /api/games/room/{roomId}/chat`
- `POST /api/games/room/{roomId}/viewers`
- `POST /api/games/auto-match`
- `POST /api/games/leaderboard`
- `GET /api/games/history`
- `GET /api/games/profile`
- `GET /api/games/mini-scores`
- `POST /api/games/mini-scores`
- `GET /api/tournaments`
- `POST /api/tournaments/join`

## Kullanılan veritabanı modelleri

Web envanterine göre:

- `GameRoom`
- `GameRoomChat`
- `GameRoomViewer`
- `GamePlay`
- `UserGameProfile`
- `SosGame`
- `SosGameChat`
- `SosGameViewer`
- `MiniGame`
- `WeeklyTournament`
- `WeeklyTournamentEntry`

## Eksik kalanlar

### Oyuna özel tahta UI'ları

Her oyunun hamle mantığı farklıdır. Bu parçada ortak web API sözleşmesiyle:

- Liste
- Oda oluşturma
- Odaya katılma
- Auto match
- Oda state polling
- Oyun chat
- Skor/sonuç alanları

eklendi. Ancak XOX, Okey, Tavla, Pişti gibi her oyuna özel tahta ve hamle UI'ları ayrı parçalarda uygulanmalıdır.

### Socket eventi

Web envanterinde oyunlar için socket event listelenmemiştir. Bu nedenle yeni socket event uydurulmadı. Realtime davranış HTTP polling ile sağlandı.

## Sonuç

Flutter oyun sistemi artık sadece statik hub/listeden ibaret değildir. Webde kullanılan mevcut oyun API'leriyle native oyun merkezi, oda girişi, auto match, polling tabanlı oda durumu, oyun chat ve skor özetleri eklendi. Oyuna özel board UI'ları bir sonraki parite parçaları olarak uygulanmalıdır.
