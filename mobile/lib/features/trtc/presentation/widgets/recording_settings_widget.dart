import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/trtc_advanced_config.dart';
import '../providers/trtc_advanced_provider.dart';

class RecordingSettingsWidget extends ConsumerStatefulWidget {
  const RecordingSettingsWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<RecordingSettingsWidget> createState() =>
      _RecordingSettingsWidgetState();
}

class _RecordingSettingsWidgetState extends ConsumerState<RecordingSettingsWidget> {
  final TextEditingController _filenameController = TextEditingController();

  @override
  void dispose() {
    _filenameController.dispose();
    super.dispose();
  }

  Future<void> _startRecording(RecordingMode mode) async {
    try {
      final repository = ref.read(trtcAdvancedRepositoryProvider);
      final config = RecordingConfig(
        mode: mode,
        filename: _filenameController.text.isNotEmpty
            ? _filenameController.text
            : 'recording_${DateTime.now().millisecondsSinceEpoch}',
        audioOnly: mode == RecordingMode.cloud,
        isRecording: true,
      );
      await repository.startRecording(config);
      ref.read(recordingConfigProvider.notifier).state = config;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıt başladı')),
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

  Future<void> _stopRecording() async {
    try {
      final repository = ref.read(trtcAdvancedRepositoryProvider);
      await repository.stopRecording();
      ref.read(recordingConfigProvider.notifier).state = RecordingConfig(
        mode: RecordingMode.none,
        audioOnly: false,
        isRecording: false,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıt durduruldu')),
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
    final recording = ref.watch(recordingConfigProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kayıt Modu',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('Yerel Kayıt'),
              subtitle: const Text('Cihazda kaydedilir'),
              trailing: recording.mode == RecordingMode.local
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              enabled: !recording.isRecording,
              onTap: !recording.isRecording
                  ? () => _startRecording(RecordingMode.local)
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: const Text('Bulut Kayıtı'),
              subtitle: const Text('Sunucuda kaydedilir'),
              trailing: recording.mode == RecordingMode.cloud
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              enabled: !recording.isRecording,
              onTap: !recording.isRecording
                  ? () => _startRecording(RecordingMode.cloud)
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: const Text('Her İkisi'),
              subtitle: const Text('Hem cihazda hem sunucuda'),
              trailing: recording.mode == RecordingMode.both
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              enabled: !recording.isRecording,
              onTap: !recording.isRecording
                  ? () => _startRecording(RecordingMode.both)
                  : null,
            ),
          ),
          if (!recording.isRecording) ...[
            const SizedBox(height: 24),
            const Text(
              'Dosya Adı',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _filenameController,
              decoration: InputDecoration(
                hintText: 'Dosya adını girin (isteğe bağlı)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: recording.isRecording ? _stopRecording : null,
              icon: Icon(recording.isRecording ? Icons.stop : Icons.fiber_manual_record),
              label: Text(
                recording.isRecording ? 'Kaydı Durdur' : 'Kayıt Seçin',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: recording.isRecording ? Colors.red : Colors.grey,
              ),
            ),
          ),
          if (recording.isRecording)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.fiber_manual_record, color: Colors.red, size: 12),
                    const SizedBox(width: 8),
                    Text(
                      'Kayıt devam ediyor: ${recording.mode.toString().split('.').last}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
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
