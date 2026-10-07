import 'package:shared_preferences/shared_preferences.dart';
import 'package:tencent_rtc_sdk/trtc_cloud_def.dart';
import 'package:tencent_rtc_sdk/tx_audio_effect_manager.dart';
import '../../../core/diagnostics/cf_diag.dart';

/// Sesli oda / canlı yayın mikrofon ayarları — backend ucu yok, TRTC SDK'ya
/// cihazda uygulanır.
class VoiceAudioSettings {
  const VoiceAudioSettings({
    this.quality = TRTCAudioQuality.speech,
    this.reverb = TXVoiceReverbType.type0,
    this.changer = TXVoiceChangerType.type0,
    this.captureVolume = 100,
    this.earMonitor = false,
  });

  final TRTCAudioQuality quality;
  final TXVoiceReverbType reverb;
  final TXVoiceChangerType changer;
  final int captureVolume;
  final bool earMonitor;

  VoiceAudioSettings copyWith({
    TRTCAudioQuality? quality,
    TXVoiceReverbType? reverb,
    TXVoiceChangerType? changer,
    int? captureVolume,
    bool? earMonitor,
  }) =>
      VoiceAudioSettings(
        quality: quality ?? this.quality,
        reverb: reverb ?? this.reverb,
        changer: changer ?? this.changer,
        captureVolume: captureVolume ?? this.captureVolume,
        earMonitor: earMonitor ?? this.earMonitor,
      );
}

const voiceQualityLabels = {
  TRTCAudioQuality.speech: ('Konuşma', 'Zayıf ağda en kararlı (16 kHz)'),
  TRTCAudioQuality.defaultMode: ('Dengeli', 'Daha doğal ses (48 kHz)'),
  TRTCAudioQuality.music: ('Müzik / Karaoke', 'Stereo, en yüksek kalite; daha fazla veri'),
};

const voiceReverbLabels = {
  TXVoiceReverbType.type0: 'Kapalı',
  TXVoiceReverbType.type1: 'Karaoke',
  TXVoiceReverbType.type2: 'Küçük oda',
  TXVoiceReverbType.type3: 'Büyük salon',
  TXVoiceReverbType.type4: 'Kalın ses',
  TXVoiceReverbType.type5: 'Gür ses',
  TXVoiceReverbType.type6: 'Metalik',
  TXVoiceReverbType.type7: 'Manyetik',
  TXVoiceReverbType.type8: 'Eterik',
  TXVoiceReverbType.type9: 'Stüdyo',
  TXVoiceReverbType.type10: 'Melodik',
};

const voiceChangerLabels = {
  TXVoiceChangerType.type0: 'Kapalı',
  TXVoiceChangerType.type1: 'Yaramaz çocuk',
  TXVoiceChangerType.type2: 'İnce ses',
  TXVoiceChangerType.type3: 'Amca',
  TXVoiceChangerType.type4: 'Ağır metal',
  TXVoiceChangerType.type5: 'Nezle',
  TXVoiceChangerType.type6: 'Yabancı aksan',
  TXVoiceChangerType.type7: 'Canavar',
  TXVoiceChangerType.type8: 'Ev kuşu',
  TXVoiceChangerType.type9: 'Elektrik',
  TXVoiceChangerType.type10: 'Makine',
  TXVoiceChangerType.type11: 'Hayalet',
};

abstract final class VoiceAudioSettingsStore {
  static const _kQuality = 'voice_audio.quality';
  static const _kReverb = 'voice_audio.reverb';
  static const _kChanger = 'voice_audio.changer';
  static const _kVolume = 'voice_audio.capture_volume';
  static const _kEar = 'voice_audio.ear_monitor';

  static VoiceAudioSettings _current = const VoiceAudioSettings();
  static bool _loaded = false;

  /// TRTC oturumu senkron okur; [ensureLoaded] oda girişinde çağrılır.
  static VoiceAudioSettings get current => _current;

  static T _at<T>(List<T> values, int? i, T fallback) =>
      i != null && i >= 0 && i < values.length ? values[i] : fallback;

  static Future<VoiceAudioSettings> ensureLoaded() async {
    if (_loaded) return _current;
    try {
      final p = await SharedPreferences.getInstance();
      const d = VoiceAudioSettings();
      _current = VoiceAudioSettings(
        quality: _at(TRTCAudioQuality.values, p.getInt(_kQuality), d.quality),
        reverb: _at(TXVoiceReverbType.values, p.getInt(_kReverb), d.reverb),
        changer: _at(TXVoiceChangerType.values, p.getInt(_kChanger), d.changer),
        captureVolume: (p.getInt(_kVolume) ?? d.captureVolume).clamp(0, 150),
        earMonitor: p.getBool(_kEar) ?? d.earMonitor,
      );
    } catch (err, st) {
      CfDiag.swallowed(err, st, CfCategory.trtc, 'voice_audio_settings:101');
    }
    _loaded = true;
    return _current;
  }

  static Future<void> save(VoiceAudioSettings s) async {
    _current = s;
    _loaded = true;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt(_kQuality, s.quality.index);
      await p.setInt(_kReverb, s.reverb.index);
      await p.setInt(_kChanger, s.changer.index);
      await p.setInt(_kVolume, s.captureVolume);
      await p.setBool(_kEar, s.earMonitor);
    } catch (err, st) {
      CfDiag.swallowed(err, st, CfCategory.trtc, 'voice_audio_settings:116');
    }
  }
}
