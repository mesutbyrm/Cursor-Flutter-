import '../../domain/entities/pf_fortune_teller.dart';

/// Canlı falcı demo verisi — production'da Firestore + TRTC/LiveKit.
class PfLiveTellerDatasource {
  static const tellers = [
    PfFortuneTeller(
      id: 't1',
      name: 'Ayşe Nur',
      bio: '15 yıllık kahve ve tarot deneyimi. Sezgisel ve şefkatli yorumlar.',
      specialties: ['Kahve', 'Tarot', 'Aşk'],
      rating: 4.9,
      reviewCount: 1240,
      pricePerMinute: 8,
      status: PfTellerStatus.online,
      isVerified: true,
    ),
    PfFortuneTeller(
      id: 't2',
      name: 'Mehmet Kaan',
      bio: 'Astroloji ve doğum haritası uzmanı. Bilimsel ve mistik sentez.',
      specialties: ['Astroloji', 'Doğum Haritası'],
      rating: 4.8,
      reviewCount: 890,
      pricePerMinute: 10,
      status: PfTellerStatus.online,
      isVerified: true,
    ),
    PfFortuneTeller(
      id: 't3',
      name: 'Zeynep Ela',
      bio: 'Rüya tabiri ve enerji okuma. Derin ve dönüştürücü seanslar.',
      specialties: ['Rüya', 'Enerji', 'Tarot'],
      rating: 4.7,
      reviewCount: 650,
      pricePerMinute: 7,
      status: PfTellerStatus.busy,
      isVerified: true,
    ),
    PfFortuneTeller(
      id: 't4',
      name: 'Can Demir',
      bio: 'Kariyer ve para odaklı fal yorumları. Net ve pratik tavsiyeler.',
      specialties: ['Kariyer', 'Para', 'Kahve'],
      rating: 4.6,
      reviewCount: 420,
      pricePerMinute: 6,
      status: PfTellerStatus.offline,
    ),
  ];

  Future<List<PfFortuneTeller>> getTellers() async => tellers;

  Future<PfFortuneTeller> getTeller(String id) async {
    return tellers.firstWhere((t) => t.id == id, orElse: () => tellers.first);
  }

  Future<PfAppointment> bookAppointment({
    required String userId,
    required String tellerId,
    required DateTime scheduledAt,
    required int durationMinutes,
    String? notes,
  }) async {
    return PfAppointment(
      id: 'apt_${DateTime.now().millisecondsSinceEpoch}',
      tellerId: tellerId,
      userId: userId,
      scheduledAt: scheduledAt,
      durationMinutes: durationMinutes,
      notes: notes,
    );
  }

  /// Sesli görüşme kanalı (Premium Fal).
  Future<String> startVoiceCall(String userId, String tellerId) async {
    return 'pf_call_${tellerId}_$userId';
  }

  Future<String> startVideoCall(String userId, String tellerId) async {
    return 'video_room_pf_${tellerId}_$userId';
  }
}
