import 'package:record/record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'short_studio_providers.dart';

Future<void> showStudioVoiceoverSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF121218),
    builder: (ctx) => _VoiceoverSheet(ref: ref),
  );
}

class _VoiceoverSheet extends StatefulWidget {
  const _VoiceoverSheet({required this.ref});

  final WidgetRef ref;

  @override
  State<_VoiceoverSheet> createState() => _VoiceoverSheetState();
}

class _VoiceoverSheetState extends State<_VoiceoverSheet> {
  final _recorder = AudioRecorder();
  var _recording = false;
  String? _path;

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _toggleRecord() async {
    if (_recording) {
      final path = await _recorder.stop();
      setState(() {
        _recording = false;
        _path = path;
      });
      if (path != null) {
        widget.ref.read(shortUploadDraftProvider.notifier).patch(
              (d) => d.copyWith(voiceoverPath: path),
            );
      }
      return;
    }
    if (!await _recorder.hasPermission()) return;
    final dir = await getTemporaryDirectory();
    final file =
        '${dir.path}/voiceover_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(), path: file);
    setState(() => _recording = true);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _recording ? 'Kayıt devam ediyor...' : 'Seslendirme',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _toggleRecord,
              icon: Icon(_recording ? Icons.stop_rounded : Icons.mic_rounded),
              label: Text(_recording ? 'Durdur' : 'Kayda başla'),
            ),
            if (_path != null) ...[
              const SizedBox(height: 8),
              Text('Kaydedildi', style: TextStyle(color: Colors.green.shade300)),
            ],
          ],
        ),
      ),
    );
  }
}
