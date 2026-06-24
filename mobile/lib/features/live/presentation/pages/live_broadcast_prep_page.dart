import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../agora/domain/entities/agora_credentials.dart';
import '../../../agora/presentation/agora_room_manager.dart';
import '../../../agora/presentation/providers/agora_providers.dart';
import '../../domain/entities/live_broadcast_prep_args.dart';
import '../../domain/entities/live_broadcast_session.dart';
import '../../domain/entities/live_guest_layout.dart';
import '../../domain/utils/live_stream_category.dart';
import '../providers/live_providers.dart';
import '../providers/live_beauty_provider.dart';
import '../widgets/live_tiktok/live_background_picker_sheet.dart';
import '../widgets/premium_2026/live_beauty_filter_sheet.dart';

/// TikTok tarzı yayın hazırlığı — kamera önizleme, misafir modu, arka plan.
class LiveBroadcastPrepPage extends ConsumerStatefulWidget {
  const LiveBroadcastPrepPage({super.key, this.args});

  final LiveBroadcastPrepArgs? args;

  @override
  ConsumerState<LiveBroadcastPrepPage> createState() =>
      _LiveBroadcastPrepPageState();
}

class _LiveBroadcastPrepPageState extends ConsumerState<LiveBroadcastPrepPage> {
  final _title = TextEditingController();
  AgoraRoomManager _agora = AgoraRoomManager();
  Key _localPreviewKey = UniqueKey();

  var _micOn = true;
  var _cameraOn = true;
  var _previewReady = false;
  var _previewLoading = false;
  var _starting = false;
  var _navigatedToRoom = false;
  String? _previewError;
  String? _backgroundUrl;
  String? _localBackgroundPath;
  String? _orphanStreamId;
  LiveGuestLayout _guestLayout = LiveGuestLayout.solo;

  LiveBroadcastPrepArgs get _args =>
      widget.args ?? const LiveBroadcastPrepArgs(category: 'Sohbet');

  @override
  void initState() {
    super.initState();
    _title.text = '${_args.category} yayını';
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPreview());
  }

  @override
  void dispose() {
    _title.dispose();
    final orphan = _orphanStreamId;
    if (orphan != null && !_navigatedToRoom && Env.useMobileAuth) {
      unawaited(
        ref.read(liveRepositoryProvider).endVideoStream(orphan).catchError((_) {}),
      );
    }
    _agora.dispose();
    super.dispose();
  }

  Future<void> _cleanupOrphanStream() async {
    final id = _orphanStreamId;
    if (id == null || _navigatedToRoom) return;
    try {
      await ref.read(liveRepositoryProvider).endVideoStream(id);
    } catch (_) {}
    _orphanStreamId = null;
  }

  Future<void> _initPreview() async {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) {
      if (mounted) {
        setState(() => _previewError = 'Kamera önizlemesi için giriş yapın');
      }
      return;
    }
    if (!_agora.isSupported) {
      if (mounted) {
        setState(
          () => _previewError = 'Kamera yalnızca Android/iOS cihazlarda çalışır',
        );
      }
      return;
    }

    if (mounted) setState(() => _previewLoading = true);
    final ok = await AgoraRoomManager.requestPermissions(video: true);
    if (!ok) {
      if (mounted) {
        setState(() {
          _previewLoading = false;
          _previewError = 'Kamera izni gerekli';
        });
      }
      return;
    }

    try {
      final previewChannel = 'preview-${user.id}';
      AgoraCredentials cred;
      try {
        cred = await ref.read(agoraRemoteProvider).fetchToken(
              channelName: previewChannel,
              role: 'host',
            );
      } catch (_) {
        cred = AgoraCredentials(
          token: '',
          channelName: previewChannel,
          appId: AgoraCredentials.defaultAppId,
        );
      }
      await _agora.startPreviewOnly(appId: cred.appId);
      ref.read(liveBeautyProvider.notifier).bindRtc(agora: _agora);
      if (mounted) {
        setState(() {
          _previewReady = true;
          _previewLoading = false;
          _previewError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _previewLoading = false;
          _previewError = ApiException.userMessage(e);
        });
      }
    }
  }

  Future<void> _startLive() async {
    if (_starting) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yayın için giriş yapmalısınız')),
      );
      return;
    }
    if (!_agora.isSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Canlı yayın yalnızca Android/iOS cihazlarda desteklenir'),
        ),
      );
      return;
    }

    setState(() => _starting = true);
    String? createdStreamId;
    try {
      if (mounted) {
        setState(() => _previewReady = false);
      }

      // Agora handoff — motor kapatma da nadiren takılabilir, koruma altına alındı.
      await _agora.shutdownForHandoff().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          // Motor kapatılamasa bile akışı durdurmuyoruz; yeni instance
          // oluşturmak güvenlidir, eski referans çöp toplanır.
        },
      );
      await Future<void>.delayed(const Duration(milliseconds: 350));
      _agora = AgoraRoomManager();

      var roomId = 'live-${DateTime.now().millisecondsSinceEpoch}';
      if (Env.useMobileAuth) {
        final apiCategory = liveStreamApiCategory(
          label: _args.category,
          isFortune: _args.isFortune,
        );
        try {
          roomId = await ref
              .read(liveRepositoryProvider)
              .createVideoStream(
                title: _title.text.trim(),
                description: _args.subtitle ?? _args.category,
                category: apiCategory,
                tags: [_args.category],
                thumbnailUrl: user.avatarUrl,
                isPrivate: false,
                isImageMode: false,
                backgroundUrl: _backgroundUrl,
              )
              .timeout(const Duration(seconds: 15));
        } on TimeoutException {
          throw StateError(
            'Yayın oluşturulamadı: sunucu yanıt vermiyor. Lütfen tekrar deneyin.',
          );
        }
        createdStreamId = roomId;
        _orphanStreamId = roomId;
      }

      final AgoraCredentials agora;
      try {
        agora = await ref
            .read(agoraRemoteProvider)
            .fetchToken(channelName: roomId, role: 'host')
            .timeout(const Duration(seconds: 15));
      } on TimeoutException {
        throw StateError(
          'Yayın anahtarı alınamadı: sunucu yanıt vermiyor. Lütfen tekrar deneyin.',
        );
      }

      if (!mounted) {
        await _cleanupOrphanStream();
        return;
      }
      final session = LiveBroadcastSession.demoHost(
        title: _title.text.trim(),
        category: _args.category,
        tags: [_args.category],
        description: _args.subtitle ?? '',
        streamerName: user.display,
        streamerHandle: user.username,
        avatarUrl: user.avatarUrl,
        backgroundUrl: _backgroundUrl,
        coverImageUrl: _localBackgroundPath ?? _backgroundUrl ?? user.avatarUrl,
      ).copyWith(
        streamId: roomId,
        agora: agora,
        hostUserId: user.id,
        initialMicOn: _micOn,
        initialCameraOn: _cameraOn,
        guestLayout: _guestLayout,
      );

      _navigatedToRoom = true;
      _orphanStreamId = null;
      await context.push('/live/room', extra: session);
      if (mounted) {
        _agora = AgoraRoomManager();
        if (context.canPop()) {
          context.pop();
        }
      }
    } catch (e) {
      if (createdStreamId != null) {
        await _cleanupOrphanStream();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
        // Buton tekrar denenebilir olsun diye önizlemeyi de sıfırlıyoruz.
        setState(() => _previewReady = false);
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _pickBackground() {
    LiveBackgroundPickerSheet.show(
      context,
      selectedUrl: _backgroundUrl,
      onSelectUrl: (url) => setState(() {
        _backgroundUrl = url;
        _localBackgroundPath = null;
      }),
      onSelectFile: (path) => setState(() {
        _localBackgroundPath = path;
        _backgroundUrl = null;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return PopScope(
      canPop: !_starting,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _starting) return;
        await _cleanupOrphanStream();
      },
      child: Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _backgroundLayer(),
          if (_previewReady && _cameraOn)
            AgoraLocalVideoView(key: _localPreviewKey, manager: _agora),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.82),
                ],
                stops: const [0.0, 0.35, 1.0],
              ),
            ),
          ),
          if (_previewError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _previewError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    if (!_previewLoading) ...[
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _initPreview,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Tekrar dene'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          if (_previewLoading && !_previewReady)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white70),
                  SizedBox(height: 12),
                  Text(
                    'Kamera açılıyor…',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(12, top > 0 ? 4 : 12, 12, 0),
                  child: Row(
                    children: [
                      _RoundBtn(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: _starting ? null : () => context.pop(),
                      ),
                      const Expanded(
                        child: Text(
                          'Yayın Hazırlığı',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      _RoundBtn(
                        icon: Icons.wallpaper_rounded,
                        onTap: _pickBackground,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CategoryChip(
                        icon: _args.icon,
                        label: _args.category,
                        onChange: () => context.pop(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Yayın başlığı (isteğe bağlı)',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                          filled: true,
                          fillColor: Colors.black.withValues(alpha: 0.35),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Misafir modu',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: LiveGuestLayout.values.map((g) {
                          final selected = _guestLayout == g;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: GestureDetector(
                                onTap: () => setState(() => _guestLayout = g),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? const Color(0xFFB832FF)
                                            .withValues(alpha: 0.35)
                                        : Colors.black.withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selected
                                          ? const Color(0xFFB832FF)
                                          : Colors.white24,
                                    ),
                                  ),
                                  child: Text(
                                    g.label,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: selected
                                          ? Colors.white
                                          : Colors.white70,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _ControlBtn(
                            icon: _cameraOn
                                ? Icons.videocam_rounded
                                : Icons.videocam_off_rounded,
                            onTap: () async {
                              final next = !_cameraOn;
                              await _agora.setCameraEnabled(next);
                              if (!mounted) return;
                              setState(() {
                                _cameraOn = next;
                                _localPreviewKey = UniqueKey();
                              });
                            },
                          ),
                          const SizedBox(width: 14),
                          _ControlBtn(
                            icon: _micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                            onTap: () {
                              _agora.setMicEnabled(!_micOn);
                              setState(() => _micOn = !_micOn);
                            },
                          ),
                          const SizedBox(width: 14),
                          _ControlBtn(
                            icon: Icons.cameraswitch_rounded,
                            onTap: _agora.switchCamera,
                          ),
                          const SizedBox(width: 14),
                          _ControlBtn(
                            icon: Icons.auto_fix_high_rounded,
                            onTap: () => showLiveBeautyFilterSheet(
                              context: context,
                              ref: ref,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 54,
                        child: FilledButton(
                          onPressed: _starting ? null : _startLive,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFB832FF), Color(0xFFFF4D8D)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFB832FF).withValues(alpha: 0.45),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            child: Center(
                              child: _starting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.sensors_rounded, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text(
                                          'Canlı Yayını Başlat',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: bottom + 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _backgroundLayer() {
    if (_localBackgroundPath != null) {
      return Image.file(
        File(_localBackgroundPath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    if (_backgroundUrl?.isNotEmpty == true) {
      return CachedNetworkImage(
        imageUrl: _backgroundUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorWidget: (_, _, _) => const ColoredBox(color: Color(0xFF1A0F32)),
      );
    }
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1548), Color(0xFF0A0614)],
        ),
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.icon,
    required this.label,
    required this.onChange,
  });

  final IconData icon;
  final String label;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB832FF).withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFD8B4FE), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          TextButton(
            onPressed: onChange,
            child: const Text('Değiştir'),
          ),
        ],
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  const _ControlBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}
