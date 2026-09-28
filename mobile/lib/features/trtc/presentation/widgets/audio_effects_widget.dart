import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/trtc_advanced_config.dart';
import '../providers/trtc_advanced_provider.dart';

class AudioEffectsWidget extends ConsumerStatefulWidget {
  const AudioEffectsWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<AudioEffectsWidget> createState() => _AudioEffectsWidgetState();
}

class _AudioEffectsWidgetState extends ConsumerState<AudioEffectsWidget> {
  Future<void> _applyEffect(AudioEffectConfig effect) async {
    try {
      final repository = ref.read(trtcAdvancedRepositoryProvider);
      await repository.applyAudioEffect(effect);
      ref.read(audioEffectProvider.notifier).state = effect;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ses efekti uygulandı')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final effect = ref.watch(audioEffectProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ses Efekti Seçin',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...AudioEffectType.values.map((effectType) {
            return Card(
              child: ListTile(
                title: Text(_getEffectName(effectType)),
                subtitle: Text(_getEffectDescription(effectType)),
                trailing: effect.effectType == effectType && effect.enabled
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () => _applyEffect(
                  AudioEffectConfig(
                    effectType: effectType,
                    intensity: 0.5,
                    enabled: effectType != AudioEffectType.none,
                  ),
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 24),
          if (effect.effectType != AudioEffectType.none)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Yoğunluk',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Slider(
                  value: effect.intensity,
                  onChanged: (value) {
                    _applyEffect(
                      AudioEffectConfig(
                        effectType: effect.effectType,
                        intensity: value,
                        enabled: true,
                      ),
                    );
                  },
                  divisions: 10,
                  label: '${(effect.intensity * 100).toInt()}%',
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _getEffectName(AudioEffectType type) {
    switch (type) {
      case AudioEffectType.none:
        return 'Yok';
      case AudioEffectType.echo:
        return 'Eko';
      case AudioEffectType.reverb:
        return 'Yankı';
      case AudioEffectType.voiceModulation:
        return 'Ses Değiştirici';
    }
  }

  String _getEffectDescription(AudioEffectType type) {
    switch (type) {
      case AudioEffectType.none:
        return 'Efekt uygulanmaz';
      case AudioEffectType.echo:
        return 'Eko efektini etkinleştir';
      case AudioEffectType.reverb:
        return 'Yankı efektini etkinleştir';
      case AudioEffectType.voiceModulation:
        return 'Sesinizi değiştir';
    }
  }
}
