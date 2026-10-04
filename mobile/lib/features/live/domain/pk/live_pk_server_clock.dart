import '../../../voice_hub/domain/pk_room/pk_server_clock.dart';

/// Canlı yayın PK geri sayımı için sunucu saati.
///
/// İki yayıncının cihaz saatleri farklı olabilir; `endsAt − serverNow` ile
/// hesaplanan sayaç iki tarafta aynı akar. Henüz örnek yoksa cihaz saati.
final PkServerClock livePkServerClock = PkServerClock();

/// Sunucu zamanında «şimdi» (UTC).
DateTime livePkNow() => livePkServerClock.now();
