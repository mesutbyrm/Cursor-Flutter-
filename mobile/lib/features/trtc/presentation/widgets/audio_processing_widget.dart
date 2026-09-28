import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/trtc_advanced_provider.dart';

class AudioProcessingWidget extends ConsumerStatefulWidget {
  const AudioProcessingWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<AudioProcessingWidget> createState() =>
      _AudioProcessingWidgetState();
}

class _AudioProcessingWidgetState extends ConsumerState<AudioProcessingWidget> {
  Future<void> _setEchoCancellation(bool enabled) async {
    try {
      final repository = ref.read(trtcAdvancedRepositoryProvider);
      await repository.setEchoCancellation(enabled);
      ref.read(echoCancellationProvider.notifier).state = enabled;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  Future<void> _setNoiseSuppression(bool enabled) async {
    try {
      final repository = ref.read(trtcAdvancedRepositoryProvider);
      await repository.setNoiseSuppression(enabled);
      ref.read(noiseSuppressionProvider.notifier).state = enabled;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  Future<void> _setAudioVolume(int volume) async {
    try {
      final repository = ref.read(trtcAdvancedRepositoryProvider);
      await repository.setAudioVolume(volume);
      ref.read(audioVolumeProvider.notifier).state = volume;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  Future<void> _setMicrophoneVolume(int volume) async {
    try {
      final repository = ref.read(trtcAdvancedRepositoryProvider);
      await repository.setMicrophoneVolume(volume);
      ref.read(microphoneVolumeProvider.notifier).state = volume;
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
    final echoCancellation = ref.watch(echoCancellationProvider);
    final noiseSuppression = ref.watch(noiseSuppressionProvider);
    final audioVolume = ref.watch(audioVolumeProvider);
    final microphoneVolume = ref.watch(microphoneVolumeProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ses İşleme',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Eko İptali',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Eko ve yankı azalt',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: echoCancellation,
                        onChanged: _setEchoCancellation,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gürültü Bastırma',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Arka plan gürültüsünü azalt',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: noiseSuppression,
                        onChanged: _setNoiseSuppression,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Ses Seviyesi',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Alıcı Sesi',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$audioVolume%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: audioVolume.toDouble(),
                    onChanged: (value) => _setAudioVolume(value.toInt()),
                    min: 0,
                    max: 100,
                    divisions: 10,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mikrofon Sesi',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$microphoneVolume%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: microphoneVolume.toDouble(),
                    onChanged: (value) => _setMicrophoneVolume(value.toInt()),
                    min: 0,
                    max: 100,
                    divisions: 10,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
