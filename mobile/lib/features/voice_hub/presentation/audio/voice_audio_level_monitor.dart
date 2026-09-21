import 'dart:async';

/// Ses seviyesi monitörü: Gerçek zamanlı ses seviyesi takibi ve konuşma algılaması
class AudioLevelSample {
  final DateTime timestamp;
  final double level; // 0-1 aralığı
  final bool isSpeaking; // Konuşma eşiğini geçti mi?
  final double peakLevel; // Pik seviye

  AudioLevelSample({
    required this.timestamp,
    required this.level,
    required this.isSpeaking,
    required this.peakLevel,
  });
}

class UserAudioMetrics {
  final String userId;
  DateTime joinedAt;
  DateTime? lastSpokeAt;
  int totalSpeakingTime = 0; // Milisaniye
  int speakingSampleCount = 0; // Kaç örnek konuştuk
  double maxAudioLevel = 0.0;
  double averageAudioLevel = 0.0;
  final List<AudioLevelSample> recentSamples = [];

  UserAudioMetrics({
    required this.userId,
    DateTime? joinedAt,
  }) : joinedAt = joinedAt ?? DateTime.now();

  void addSample(AudioLevelSample sample) {
    recentSamples.add(sample);
    // Son 100 örneği tut
    if (recentSamples.length > 100) {
      recentSamples.removeAt(0);
    }

    // Istatistikler güncelle
    if (sample.level > maxAudioLevel) {
      maxAudioLevel = sample.level;
    }

    // Ortalama ses seviyesi hesapla
    if (recentSamples.isNotEmpty) {
      averageAudioLevel = recentSamples.fold(0.0, (sum, s) => sum + s.level) / recentSamples.length;
    }

    // Konuşma süresi ve sayısı
    if (sample.isSpeaking) {
      lastSpokeAt = sample.timestamp;
      speakingSampleCount++;
    }
  }

  int getSpeakingDurationMs() {
    if (recentSamples.isEmpty) return totalSpeakingTime;
    int duration = totalSpeakingTime;
    bool wasSpeaking = false;
    DateTime? speakingStartTime;

    for (final sample in recentSamples) {
      if (sample.isSpeaking && !wasSpeaking) {
        speakingStartTime = sample.timestamp;
        wasSpeaking = true;
      } else if (!sample.isSpeaking && wasSpeaking) {
        if (speakingStartTime != null) {
          duration += sample.timestamp.difference(speakingStartTime).inMilliseconds;
        }
        wasSpeaking = false;
      }
    }

    // Son parça açık bırakılmışsa ekle
    if (wasSpeaking && speakingStartTime != null) {
      duration += DateTime.now().difference(speakingStartTime).inMilliseconds;
    }

    return duration;
  }

  void reset() {
    recentSamples.clear();
    lastSpokeAt = null;
    totalSpeakingTime = 0;
    speakingSampleCount = 0;
    maxAudioLevel = 0.0;
    averageAudioLevel = 0.0;
  }
}

class VoiceAudioLevelMonitor {
  // Konuşma eşiği (0-1): bu seviyenin üzerinde = konuşuyor
  static const double speakingThreshold = 0.15;
  // Sessizlik eşiği: bu seviyenin altında = sessiz (konuşmayı bitirdi)
  static const double silenceThreshold = 0.08;
  // Dinlenme periyodu: her N ms'de bir örnek
  static const int samplingPeriodMs = 100;

  final Map<String, UserAudioMetrics> _userMetrics = {};
  late Timer _monitoringTimer;
  bool _isMonitoring = false;

  Stream<UserAudioMetrics>? _metricsStream;
  final StreamController<UserAudioMetrics> _metricsController =
      StreamController<UserAudioMetrics>.broadcast();

  Stream<UserAudioMetrics> get metricsStream => _metricsController.stream;

  /// Monitörü başlat
  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;

    _monitoringTimer = Timer.periodic(
      const Duration(milliseconds: samplingPeriodMs),
      (_) => _processSamples(),
    );
  }

  /// Monitörü durdur
  void stopMonitoring() {
    if (!_isMonitoring) return;
    _isMonitoring = false;
    _monitoringTimer.cancel();
  }

  /// Kullanıcı için ses seviyesi örneği ekle
  void recordAudioLevel(String userId, double level) {
    if (level < 0.0 || level > 1.0) {
      throw ArgumentError('Audio level must be between 0.0 and 1.0');
    }

    final metrics = _userMetrics.putIfAbsent(
      userId,
      () => UserAudioMetrics(userId: userId),
    );

    final now = DateTime.now();
    final isSpeaking = _detectSpeaking(level, metrics);
    final sample = AudioLevelSample(
      timestamp: now,
      level: level,
      isSpeaking: isSpeaking,
      peakLevel: metrics.maxAudioLevel,
    );

    metrics.addSample(sample);
  }

  /// Konuşmayı algıla (histerez ile)
  bool _detectSpeaking(double level, UserAudioMetrics metrics) {
    if (metrics.recentSamples.isEmpty) {
      return level >= speakingThreshold;
    }

    final lastSample = metrics.recentSamples.last;
    if (lastSample.isSpeaking) {
      // Konuşuyordu, stille süre
      return level >= silenceThreshold;
    } else {
      // Sessizdi, konuşmaya başla
      return level >= speakingThreshold;
    }
  }

  /// Örnek işleme ve istatistik güncelleme
  void _processSamples() {
    for (final metrics in _userMetrics.values) {
      _metricsController.add(metrics);
    }
  }

  /// Kullanıcı metriklerini al
  UserAudioMetrics? getMetrics(String userId) => _userMetrics[userId];

  /// Tüm kullanıcı metriklerini al
  Map<String, UserAudioMetrics> getAllMetrics() => Map.from(_userMetrics);

  /// Belirli bir kullanıcının son N örneğini al
  List<AudioLevelSample> getRecentSamples(String userId, {int count = 20}) {
    final metrics = _userMetrics[userId];
    if (metrics == null) return [];
    return metrics.recentSamples.skip(
      (metrics.recentSamples.length - count).clamp(0, metrics.recentSamples.length),
    ).toList();
  }

  /// Oda-genelinde İstatistikler
  Map<String, dynamic> getRoomStatistics() {
    if (_userMetrics.isEmpty) {
      return {
        'totalUsers': 0,
        'speakingUsers': 0,
        'averageAudioLevel': 0.0,
        'peakAudioLevel': 0.0,
        'totalSpeakingTime': 0,
      };
    }

    final speakingUsers = _userMetrics.values
        .where((m) => m.recentSamples.isNotEmpty && m.recentSamples.last.isSpeaking)
        .length;
    final avgLevel = _userMetrics.values.isEmpty
        ? 0.0
        : _userMetrics.values.fold(0.0, (sum, m) => sum + m.averageAudioLevel) /
            _userMetrics.values.length;
    final peakLevel = _userMetrics.values.isEmpty
        ? 0.0
        : _userMetrics.values.fold(0.0, (max, m) => max > m.maxAudioLevel ? max : m.maxAudioLevel);

    return {
      'totalUsers': _userMetrics.length,
      'speakingUsers': speakingUsers,
      'averageAudioLevel': avgLevel,
      'peakAudioLevel': peakLevel,
      'totalSpeakingTime': _userMetrics.values.fold(0, (sum, m) => sum + m.totalSpeakingTime),
    };
  }

  /// Odam top konuşmacıları al
  List<UserAudioMetrics> getTopSpeakers({int limit = 5}) {
    final sorted = _userMetrics.values.toList()
      ..sort((a, b) => b.getSpeakingDurationMs().compareTo(a.getSpeakingDurationMs()));
    return sorted.take(limit).toList();
  }

  /// En çok ses seviyesi yüksek olan kullanıcılar
  List<UserAudioMetrics> getHighestAudioLevelUsers({int limit = 5}) {
    final sorted = _userMetrics.values.toList()
      ..sort((a, b) => b.maxAudioLevel.compareTo(a.maxAudioLevel));
    return sorted.take(limit).toList();
  }

  /// Kullanıcı metriklerini sıfırla
  void resetUserMetrics(String userId) {
    final metrics = _userMetrics[userId];
    if (metrics != null) {
      metrics.reset();
    }
  }

  /// Tüm metrikler sıfırla
  void resetAllMetrics() {
    _userMetrics.clear();
  }

  /// Oturumu bitir: Bir kullanıcıyı çıkar
  void removeUser(String userId) {
    _userMetrics.remove(userId);
  }

  /// Temizle ve kapatır
  void dispose() {
    stopMonitoring();
    _metricsController.close();
    _userMetrics.clear();
  }
}
