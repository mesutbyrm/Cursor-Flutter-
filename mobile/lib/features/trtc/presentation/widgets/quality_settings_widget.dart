import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/trtc_advanced_config.dart';
import '../providers/trtc_advanced_provider.dart';

class QualitySettingsWidget extends ConsumerStatefulWidget {
  const QualitySettingsWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<QualitySettingsWidget> createState() =>
      _QualitySettingsWidgetState();
}

class _QualitySettingsWidgetState extends ConsumerState<QualitySettingsWidget> {
  Future<void> _setQuality(QualityConfig quality) async {
    try {
      final repository = ref.read(trtcAdvancedRepositoryProvider);
      await repository.setQuality(quality);
      ref.read(qualityConfigProvider.notifier).state = quality;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kalite ayarı güncellendi')),
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
    final quality = ref.watch(qualityConfigProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Video Kalitesi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('Düşük'),
              subtitle: const Text('480p 15fps - Daha az bant'),
              trailing: quality.level == QualityLevel.low
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () => _setQuality(QualityConfig.low()),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: const Text('Orta'),
              subtitle: const Text('480p 24fps - Dengeli'),
              trailing: quality.level == QualityLevel.medium
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () => _setQuality(QualityConfig.medium()),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: const Text('Yüksek'),
              subtitle: const Text('720p 30fps - En iyi görüntü'),
              trailing: quality.level == QualityLevel.high
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () => _setQuality(QualityConfig.high()),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: const Text('Ultra'),
              subtitle: const Text('1080p 60fps - Maksimum kalite'),
              trailing: quality.level == QualityLevel.ultra
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () => _setQuality(QualityConfig.ultra()),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Mevcut Ayarlar',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _SettingRow('Çözünürlük', '${quality.width}x${quality.height}'),
          _SettingRow('Bit Hızı', '${quality.bitrate} kbps'),
          _SettingRow('FPS', '${quality.frameRate} fps'),
          _SettingRow('Donanım Hızlandırma', quality.hardwareAcceleration ? 'Açık' : 'Kapalı'),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final String value;

  const _SettingRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
