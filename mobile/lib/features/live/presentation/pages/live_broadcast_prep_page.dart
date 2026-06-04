import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../profile/presentation/widgets/premium/profile_glass.dart';
import '../../../../core/config/env.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/live_broadcast_session.dart';
import '../providers/live_providers.dart';
import '../../../trtc/presentation/providers/trtc_providers.dart';
import '../../../trtc/presentation/trtc_room_manager.dart';

/// Canlı yayın hazırlığı — neon cam arayüz.
class LiveBroadcastPrepPage extends ConsumerStatefulWidget {
  const LiveBroadcastPrepPage({super.key});

  @override
  ConsumerState<LiveBroadcastPrepPage> createState() =>
      _LiveBroadcastPrepPageState();
}

class _LiveBroadcastPrepPageState extends ConsumerState<LiveBroadcastPrepPage> {
  final _title = TextEditingController(
    text: 'Bugün sizinle harika bir yayın yapacağız! 💜',
  );
  final _description = TextEditingController(
    text: 'Sohbet, müzik ve eğlence — hepinizi bekliyorum!',
  );

  String _category = 'Sohbet';
  final _tags = <String>['#sohbet', '#müzik'];

  final _settings = <String, bool>{
    'Kamera': true,
    'Mikrofon': true,
    'Güzellik': true,
    'Flaş': false,
    'Konum': false,
    'Özel': false,
  };

  static const _categories = [
    ('Sohbet', Icons.chat_bubble_rounded),
    ('Müzik', Icons.music_note_rounded),
    ('Eğlence', Icons.celebration_rounded),
    ('Oyun', Icons.sports_esports_rounded),
    ('Fitness', Icons.fitness_center_rounded),
    ('Sanat', Icons.palette_rounded),
  ];

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  var _starting = false;

  Future<void> _startLive() async {
    if (_starting) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yayın için giriş yapmalısınız')),
      );
      return;
    }

    setState(() => _starting = true);
    try {
      final wantCamera = _settings['Kamera'] ?? true;
      final wantMic = _settings['Mikrofon'] ?? true;
      if (!wantMic && !wantCamera) {
        throw StateError('Yayın için en az mikrofon veya kamera açık olmalı');
      }
      final permsOk = await TrtcRoomManager.requestPermissions(video: wantCamera);
      if (!permsOk) {
        throw StateError(
          'Mikrofon veya kamera izni verilmedi. Ayarlardan izin verip tekrar deneyin.',
        );
      }

      var roomId = 'live-${DateTime.now().millisecondsSinceEpoch}';
      if (Env.useMobileAuth) {
        roomId = await ref.read(liveRepositoryProvider).createVideoStream(
              title: _title.text.trim(),
              description: _description.text.trim(),
              category: _category,
              tags: _tags,
            );
      }

      final trtc = await ref.read(trtcRemoteProvider).fetchUserSig(
            userId: user.id,
            roomId: roomId,
          );

      if (!mounted) return;
      final session = LiveBroadcastSession.demoHost(
        title: _title.text.trim(),
        category: _category,
        tags: _tags,
        description: _description.text.trim(),
        streamerName: user.display,
        streamerHandle: user.username,
        avatarUrl: user.avatarUrl,
      ).copyWith(
        streamId: roomId,
        trtc: trtc,
        hostUserId: user.id,
        initialMicOn: wantMic,
        initialCameraOn: wantCamera,
      );

      context.push('/live/room', extra: session);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: Column(
          children: [
            SizedBox(height: top + 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  DiscoverIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Canlı Yayın Hazırlığı',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  DiscoverIconButton(
                    icon: Icons.settings_rounded,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PreviewCard(
                      displayName: user?.display ?? 'Cemre',
                      username: user?.username ?? 'cemreofficial',
                      avatarUrl: user?.avatarUrl,
                    ),
                    SizedBox(height: 22),
                    Text(
                      'Yayın Bilgileri',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 12),
                    ProfileGlass(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _title,
                            style: TextStyle(
                              color: context.colors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: authLikeDecoration('Yayın başlığı'),
                          ),
                          SizedBox(height: 16),
                          SizedBox(
                            height: 40,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _categories.length,
                              separatorBuilder: (_, _) =>
                                  SizedBox(width: 8),
                              itemBuilder: (ctx, i) {
                                final c = _categories[i];
                                final selected = _category == c.$1;
                                return FilterChip(
                                  selected: selected,
                                  showCheckmark: false,
                                  avatar: Icon(
                                    c.$2,
                                    size: 16,
                                    color: selected
                                        ? Colors.white
                                        : context.colors.onSurfaceMuted,
                                  ),
                                  label: Text(c.$1),
                                  labelStyle: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: selected
                                        ? Colors.white
                                        : context.colors.onSurfaceVariant,
                                  ),
                                  selectedColor: AppThemeColors.accentPink,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.06),
                                  side: BorderSide(
                                    color: selected
                                        ? AppThemeColors.accentPink
                                        : AppThemeColors.accentPurple
                                            .withValues(alpha: 0.3),
                                  ),
                                  onSelected: (_) =>
                                      setState(() => _category = c.$1),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final t in _tags)
                                Chip(
                                  label: Text(t),
                                  deleteIcon: Icon(Icons.close, size: 16),
                                  onDeleted: () =>
                                      setState(() => _tags.remove(t)),
                                  backgroundColor:
                                      AppThemeColors.accentPurple.withValues(
                                    alpha: 0.2,
                                  ),
                                  side: BorderSide.none,
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ActionChip(
                                avatar: Icon(Icons.add, size: 16),
                                label: Text('Etiket'),
                                onPressed: () {
                                  setState(() {
                                    _tags.add('#yeni${_tags.length + 1}');
                                  });
                                },
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.06),
                              ),
                            ],
                          ),
                          SizedBox(height: 14),
                          TextField(
                            controller: _description,
                            maxLines: 3,
                            maxLength: 200,
                            style: TextStyle(
                              color: context.colors.onSurface,
                              fontSize: 14,
                            ),
                            decoration: authLikeDecoration(
                              'Açıklama',
                              counter: '${_description.text.length}/200',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 22),
                    Text(
                      'Yayın Ayarları',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.05,
                      children: [
                        for (final e in _settings.entries)
                          _SettingTile(
                            label: e.key,
                            enabled: e.value,
                            icon: _iconForSetting(e.key),
                            onTap: () => setState(
                              () => _settings[e.key] = !e.value,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 28),
                    _StartLiveButton(
                      loading: _starting,
                      onPressed: _starting ? null : _startLive,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconForSetting(String key) => switch (key) {
        'Kamera' => Icons.videocam_rounded,
        'Mikrofon' => Icons.mic_rounded,
        'Güzellik' => Icons.face_retouching_natural_rounded,
        'Flaş' => Icons.flash_on_rounded,
        'Konum' => Icons.location_on_rounded,
        _ => Icons.lock_rounded,
      };
}

InputDecoration authLikeDecoration(String label, {String? counter}) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: AppThemeColors.dark.onSurfaceMuted),
    counterText: counter,
    counterStyle: TextStyle(color: AppThemeColors.dark.onSurfaceMuted, fontSize: 11),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.04),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: AppThemeColors.accentPurple.withValues(alpha: 0.25),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: AppThemeColors.accentPurple.withValues(alpha: 0.2),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppThemeColors.accentPink),
    ),
  );
}

class _PreviewCard extends StatefulWidget {
  const _PreviewCard({
    required this.displayName,
    required this.username,
    this.avatarUrl,
  });

  final String displayName;
  final String username;
  final String? avatarUrl;

  @override
  State<_PreviewCard> createState() => _PreviewCardState();
}

class _PreviewCardState extends State<_PreviewCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppThemeColors.accentPink.withValues(alpha: 0.55),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppThemeColors.accentPurple.withValues(alpha: 0.35),
            blurRadius: 28,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF3D1F5C),
                    Color(0xFF1A0F32),
                    Color(0xFF0F0C29),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: Icon(
                Icons.person_rounded,
                size: 120,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      UserAvatar(url: widget.avatarUrl, radius: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.displayName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.verified_rounded,
                                  size: 14,
                                  color: AppThemeColors.diamondBlue,
                                ),
                              ],
                            ),
                            Text(
                              '@${widget.username}',
                              style: TextStyle(
                                color: context.colors.onSurfaceMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppThemeColors.liveRed,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'LIVE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppThemeColors.onlineGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Yayına Hazırsın',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Bağlantı stabil · Ses testi tamam',
                              style: TextStyle(
                                color: context.colors.onSurfaceMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (ctx, _) => _AudioBars(t: _pulse.value),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioBars extends StatelessWidget {
  const _AudioBars({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(5, (i) {
        final h = 8.0 + (12 + i * 3) * (0.4 + 0.6 * ((t + i * 0.15) % 1.0));
        return Container(
          width: 4,
          height: h,
          margin: const EdgeInsets.only(left: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: context.colors.brandGradient,
          ),
        );
      }),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.label,
    required this.enabled,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ProfileGlass(
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      borderRadius: 16,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: enabled ? AppThemeColors.accentCyan : context.colors.onSurfaceMuted,
            size: 24,
          ),
          SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            enabled ? 'Açık' : 'Kapalı',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: enabled ? AppThemeColors.onlineGreen : AppThemeColors.liveRed,
            ),
          ),
        ],
      ),
    );
  }
}

class _StartLiveButton extends StatelessWidget {
  const _StartLiveButton({required this.onPressed, this.loading = false});

  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: onPressed == null && !loading
                ? null
                : context.colors.brandGradient,
            color: onPressed == null && !loading
                ? Colors.white.withValues(alpha: 0.1)
                : null,
            boxShadow: onPressed == null
                ? null
                : AppThemeColors.glowShadow(AppThemeColors.accentPink, blur: 28),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else ...[
                Icon(Icons.fiber_manual_record_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'CANLI YAYINA BAŞLA',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
