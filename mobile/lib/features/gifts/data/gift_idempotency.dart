import 'package:uuid/uuid.dart';

/// Parasal hediye POST'ları için çift işlem koruması (resmî entegrasyon §13.3).
String newGiftIdempotencyKey() => const Uuid().v4();
