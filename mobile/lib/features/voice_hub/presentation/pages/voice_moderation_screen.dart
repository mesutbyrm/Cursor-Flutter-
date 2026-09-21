import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/voice_presence_provider.dart';

/// Ses moderation ekranı: Sessiz kullanıcılar, konuşma analitiği, kick/ban kontrolleri, ses seviyesi monitörü
class VoiceModerationScreen extends ConsumerStatefulWidget {
  const VoiceModerationScreen({
    super.key,
    required this.roomId,
    this.onKickUser,
    this.onBanUser,
    this.onMuteUser,
  });

  final String roomId;
  final Function(String userId)? onKickUser;
  final Function(String userId)? onBanUser;
  final Function(String userId)? onMuteUser;

  @override
  ConsumerState<VoiceModerationScreen> createState() => _VoiceModerationScreenState();
}

class _VoiceModerationScreenState extends ConsumerState<VoiceModerationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ses Odası Moderation'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sessiz Kullanıcılar', icon: Icon(Icons.mic_off)),
            Tab(text: 'Analitiği', icon: Icon(Icons.bar_chart)),
            Tab(text: 'Ses Monitörü', icon: Icon(Icons.equalizer)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMutedUsersTab(),
          _buildAnalyticsTab(),
          _buildAudioMonitorTab(),
        ],
      ),
    );
  }

  /// Sessiz kullanıcılar sekmesi
  Widget _buildMutedUsersTab() {
    return ref.watch(roomPresenceProvider(widget.roomId)).when(
      data: (presences) {
        final mutedUsers = presences.where((p) => !p.micEnabled).toList();

        if (mutedUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mic, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Sessiz kullanıcı yok',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: mutedUsers.length,
          itemBuilder: (context, index) {
            final user = mutedUsers[index];
            return _buildMutedUserCard(user);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Hata: $error'),
      ),
    );
  }

  /// Sessiz kullanıcı kartı
  Widget _buildMutedUserCard(EnhancedPresence user) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: user.avatarUrl != null
              ? NetworkImage(user.avatarUrl!)
              : null,
          child: user.avatarUrl == null
              ? Text(user.displayName.isNotEmpty ? user.displayName[0] : '?')
              : null,
        ),
        title: Text(user.displayName),
        subtitle: Text(
          'Oturma süresi: ${_formatDuration(DateTime.now().difference(user.joinedAt))}',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) {
            if (action == 'kick') {
              widget.onKickUser?.call(user.userId);
            } else if (action == 'ban') {
              widget.onBanUser?.call(user.userId);
            } else if (action == 'unmute') {
              widget.onMuteUser?.call(user.userId);
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem(
              value: 'unmute',
              child: Row(
                children: [Icon(Icons.mic), SizedBox(width: 8), Text('Mikrofon Aç')],
              ),
            ),
            const PopupMenuItem(
              value: 'kick',
              child: Row(
                children: [Icon(Icons.exit_to_app), SizedBox(width: 8), Text('Odadan Çıkar')],
              ),
            ),
            const PopupMenuItem(
              value: 'ban',
              child: Row(
                children: [Icon(Icons.block), SizedBox(width: 8), Text('Yasakla')],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Konuşma analitiği sekmesi
  Widget _buildAnalyticsTab() {
    return ref.watch(roomPresenceStatsProvider(widget.roomId)).when(
      data: (stats) {
        final totalUsers = stats['totalUsers'] ?? 0;
        final speakingUsers = stats['speakingUsers'] ?? 0;
        final avgAudioLevel = (stats['avgAudioLevel'] ?? 0.0).toDouble();
        final activeMics = stats['activeMics'] ?? 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Oda Özeti',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                title: 'Toplam Kullanıcı',
                value: '$totalUsers',
                icon: Icons.people,
                color: Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                title: 'Konuşan Kullanıcı',
                value: '$speakingUsers',
                icon: Icons.mic,
                color: Colors.green,
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                title: 'Aktif Mikrofon',
                value: '$activeMics',
                icon: Icons.headset_mic,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              Text(
                'Ortalama Ses Seviyesi',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _buildAudioLevelBar(avgAudioLevel),
              const SizedBox(height: 24),
              Text(
                'Konuşma Süresi Dağılımı',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ref.watch(roomPresenceProvider(widget.roomId)).when(
                data: (presences) {
                  final activeSpeakers = presences
                      .where((p) => p.isSpeaking || p.speakingDuration > 0)
                      .toList()
                    ..sort((a, b) => b.speakingDuration.compareTo(a.speakingDuration));

                  if (activeSpeakers.isEmpty) {
                    return Text(
                      'Henüz konuşan yok',
                      style: TextStyle(color: Colors.grey[600]),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activeSpeakers.length,
                    itemBuilder: (context, index) {
                      final user = activeSpeakers[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  user.displayName,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  _formatDuration(Duration(milliseconds: user.speakingDuration)),
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (user.speakingDuration / 30000).clamp(0.0, 1.0),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => Text('Hata: $error'),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Hata: $error'),
      ),
    );
  }

  /// Ses monitörü sekmesi
  Widget _buildAudioMonitorTab() {
    return ref.watch(roomPresenceProvider(widget.roomId)).when(
      data: (presences) {
        final activeUsers = presences.where((p) => p.micEnabled).toList()
          ..sort((a, b) => b.audioLevel.compareTo(a.audioLevel));

        if (activeUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.equalizer, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Mikrofon açık hiç kullanıcı yok',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activeUsers.length,
          itemBuilder: (context, index) {
            final user = activeUsers[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: user.avatarUrl != null
                            ? NetworkImage(user.avatarUrl!)
                            : null,
                        child: user.avatarUrl == null
                            ? Text(user.displayName.isNotEmpty ? user.displayName[0] : '?')
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              user.isSpeaking ? '🔴 Konuşuyor' : '⚪ Sessiz',
                              style: TextStyle(
                                fontSize: 12,
                                color: user.isSpeaking ? Colors.red : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${(user.audioLevel * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildAudioLevelVisualization(user.audioLevel),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Hata: $error'),
      ),
    );
  }

  /// Ses seviyesi animasyonlu gösterimi
  Widget _buildAudioLevelVisualization(double level) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(4),
      child: Stack(
        children: [
          // Arka plan çubuklar
          Row(
            children: List.generate(
              20,
              (index) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Aktif çubuklar
          Row(
            children: List.generate(
              20,
              (index) {
                final isActive = (index / 20) < level;
                final color = _getAudioLevelColor(index / 20);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      decoration: BoxDecoration(
                        color: isActive ? color : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// İstatistik kartı
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Ses seviyesi gösterge çubuğu
  Widget _buildAudioLevelBar(double level) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: level,
            minHeight: 24,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              _getAudioLevelColor(level),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${(level * 100).toStringAsFixed(1)}%',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  /// Ses seviyesine göre renk döndürür
  Color _getAudioLevelColor(double level) {
    if (level < 0.33) return Colors.green;
    if (level < 0.66) return Colors.orange;
    return Colors.red;
  }

  /// Süre formatla
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
