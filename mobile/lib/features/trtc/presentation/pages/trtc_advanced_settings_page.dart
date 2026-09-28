import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/trtc_advanced_config.dart';
import '../providers/trtc_advanced_provider.dart';
import '../widgets/audio_effects_widget.dart';
import '../widgets/quality_settings_widget.dart';
import '../widgets/recording_settings_widget.dart';
import '../widgets/audio_processing_widget.dart';

class TRTCAdvancedSettingsPage extends ConsumerWidget {
  const TRTCAdvancedSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('TRTC Gelişmiş Ayarlar'),
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Ses Efektleri'),
              Tab(text: 'Kalite'),
              Tab(text: 'Kayıt'),
              Tab(text: 'İşleme'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const AudioEffectsWidget(),
            const QualitySettingsWidget(),
            const RecordingSettingsWidget(),
            const AudioProcessingWidget(),
          ],
        ),
      ),
    );
  }
}
