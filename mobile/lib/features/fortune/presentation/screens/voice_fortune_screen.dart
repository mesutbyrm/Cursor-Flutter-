import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/voice_fortune_provider.dart';

class VoiceFortuneScreen extends ConsumerStatefulWidget {
  const VoiceFortuneScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<VoiceFortuneScreen> createState() => _VoiceFortuneScreenState();
}

class _VoiceFortuneScreenState extends ConsumerState<VoiceFortuneScreen> {
  bool _isRecording = false;
  int _recordingDuration = 0;
  int _currentPage = 0;
  final int _pageSize = 20;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sesli Fal'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.purple[50],
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                if (_isRecording)
                  Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red[100],
                          border: Border.all(
                            color: Colors.red[400]!,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.mic, size: 40, color: Colors.red),
                              const SizedBox(height: 8),
                              Text(
                                '${_recordingDuration ~/ 60}:${(_recordingDuration % 60).toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      Icon(
                        Icons.mic_none,
                        size: 48,
                        color: Colors.purple[400],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Sesli Fal Kaydı',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sorunuzu veya fal deneyiminizi anlatın',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isRecording)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.stop),
                        label: const Text('Kaydı Dur'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        onPressed: _stopRecording,
                      )
                    else
                      ElevatedButton.icon(
                        icon: const Icon(Icons.mic),
                        label: const Text('Kayıt Başlat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[400],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        onPressed: _startRecording,
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final voiceFortuesAsync = ref.watch(
                  voiceFortuesProvider((
                    limit: _pageSize,
                    offset: _currentPage * _pageSize,
                  )),
                );

                return voiceFortuesAsync.when(
                  data: (voiceFortunes) {
                    if (voiceFortunes.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.mic_none,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Henüz sesli fal kaydı yok',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: voiceFortunes.length,
                      itemBuilder: (context, index) {
                        final voiceFortune = voiceFortunes[index];
                        return _buildVoiceFortuneCard(context, ref, voiceFortune);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(
                    child: Text('Hata: $err'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceFortuneCard(BuildContext context, WidgetRef ref, VoiceFortune voiceFortune) {
    final statusColor = _getStatusColor(voiceFortune.processingStatus);
    final statusLabel = _getStatusLabel(voiceFortune.processingStatus);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.mic, color: Colors.purple[400], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Ses Kaydı',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple[400],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${voiceFortune.duration} sn',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (voiceFortune.processingStatus == 'pending')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: 0.5,
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation(Colors.purple),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Transkripsiyon işleniyor...',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            if (voiceFortune.transcription != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Transkripsiyon',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    voiceFortune.transcription!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('d MMMM HH:mm', 'tr_TR').format(voiceFortune.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                if (voiceFortune.processingStatus == 'completed')
                  ElevatedButton.icon(
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    label: const Text('Fal Oluştur'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[400],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                    onPressed: () => _generateFortune(ref, voiceFortune.id),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.amber[400]!;
      case 'processing':
        return Colors.blue[400]!;
      case 'completed':
        return Colors.green[400]!;
      case 'failed':
        return Colors.red[400]!;
      default:
        return Colors.grey[400]!;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Bekleniyor';
      case 'processing':
        return 'İşleniyor';
      case 'completed':
        return 'Tamamlandı';
      case 'failed':
        return 'Başarısız';
      default:
        return status;
    }
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordingDuration = 0;
    });

    _simulateRecording();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ses kaydı başladı')),
    );
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ses kaydı durduruldu ve işleme alındı')),
    );
  }

  void _simulateRecording() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_isRecording && mounted) {
        setState(() {
          _recordingDuration++;
        });
        _simulateRecording();
      }
    });
  }

  void _generateFortune(WidgetRef ref, String voiceFortuneId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fal oluşturuluyor...')),
    );
  }
}
