import 'package:flutter/material.dart';
import 'package:tencent_rtc_sdk/trtc_cloud_def.dart';
import 'package:tencent_rtc_sdk/tx_audio_effect_manager.dart';

import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/discover/discover_tab_pages.dart';
import '../../domain/voice_audio_settings.dart';
import '../trtc_room_manager.dart';

/// `/settings/voice-audio` — mikrofon kalitesi ve ses efektleri (TRTC SDK).
class VoiceAudioSettingsPage extends StatefulWidget {
  const VoiceAudioSettingsPage({super.key});

  @override
  State<VoiceAudioSettingsPage> createState() => _VoiceAudioSettingsPageState();
}

class _VoiceAudioSettingsPageState extends State<VoiceAudioSettingsPage> {
  VoiceAudioSettings? _s;

  @override
  void initState() {
    super.initState();
    VoiceAudioSettingsStore.ensureLoaded().then((s) {
      if (mounted) setState(() => _s = s);
    });
  }

  Future<void> _update(VoiceAudioSettings next) async {
    setState(() => _s = next);
    await VoiceAudioSettingsStore.save(next);
    TrtcRoomManager.applyVoiceSettingsToActiveSession();
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    final c = context.colors;
    return DiscoverSubPage(
      title: 'Ses ayarları',
      subtitle: 'Sesli oda ve canlı yayın mikrofonu',
      body: s == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              children: [
                _label('Ses kalitesi'),
                Card(
                  child: RadioGroup<TRTCAudioQuality>(
                    groupValue: s.quality,
                    onChanged: (v) {
                      if (v != null) _update(s.copyWith(quality: v));
                    },
                    child: Column(
                      children: [
                        for (final e in voiceQualityLabels.entries)
                          RadioListTile<TRTCAudioQuality>(
                            value: e.key,
                            title: Text(e.value.$1),
                            subtitle: Text(e.value.$2),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                  child: Text(
                    'Kalite değişikliği mikrofonu bir sonraki açışında geçerli olur.',
                    style: TextStyle(color: c.onSurfaceMuted, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
                _label('Mikrofon seviyesi: ${s.captureVolume}'),
                Card(
                  child: Slider(
                    value: s.captureVolume.toDouble(),
                    max: 150,
                    divisions: 30,
                    label: '${s.captureVolume}',
                    onChanged: (v) =>
                        setState(() => _s = s.copyWith(captureVolume: v.round())),
                    onChangeEnd: (v) =>
                        _update(s.copyWith(captureVolume: v.round())),
                  ),
                ),
                const SizedBox(height: 16),
                _label('Efektler'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.surround_sound_rounded),
                        title: const Text('Yankı'),
                        trailing: DropdownButton<TXVoiceReverbType>(
                          value: s.reverb,
                          underline: const SizedBox.shrink(),
                          items: [
                            for (final e in voiceReverbLabels.entries)
                              DropdownMenuItem(value: e.key, child: Text(e.value)),
                          ],
                          onChanged: (v) {
                            if (v != null) _update(s.copyWith(reverb: v));
                          },
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.record_voice_over_rounded),
                        title: const Text('Ses değiştirici'),
                        trailing: DropdownButton<TXVoiceChangerType>(
                          value: s.changer,
                          underline: const SizedBox.shrink(),
                          items: [
                            for (final e in voiceChangerLabels.entries)
                              DropdownMenuItem(value: e.key, child: Text(e.value)),
                          ],
                          onChanged: (v) {
                            if (v != null) _update(s.copyWith(changer: v));
                          },
                        ),
                      ),
                      SwitchListTile(
                        secondary: const Icon(Icons.headphones_rounded),
                        title: const Text('Kulaklıkta kendini duy'),
                        subtitle: const Text('Kablolu kulaklıkla kullanın'),
                        value: s.earMonitor,
                        onChanged: (v) => _update(s.copyWith(earMonitor: v)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => _update(const VoiceAudioSettings()),
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Varsayılanlara dön'),
                ),
              ],
            ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
        ),
      );
}
