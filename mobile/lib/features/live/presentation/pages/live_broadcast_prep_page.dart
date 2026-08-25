import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../core/config/env.dart';
import '../../../../core/auth/bot_account_guard.dart';
import '../../../../core/auth/bot_account_provider.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/live_event_log.dart';
import '../../../../core/network/token_storage.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../trtc/domain/entities/trtc_credentials.dart';
import '../../../trtc/presentation/trtc_room_manager.dart';
import '../../../trtc/presentation/providers/trtc_providers.dart';
import '../../data/host_live_stream_recovery.dart';
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
  TrtcRoomManager _trtc = TrtcRoomManager();
  final _localPreviewKey = GlobalKey(debugLabel: 'prep-local-preview');

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
  LiveBroadcastSession? _resumableSession;
  var _checkingResume = true;

  LiveBroadcastPrepArgs get _args =>
      widget.args ?? const LiveBroadcastPrepArgs(category: 'Sohbet');

  @override
  void initState() {
    super.initState();
    _title.text = '${_args.category} yayını';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPreview();
      unawaited(_checkResumableStream());
    });
  }

  Future<void> _checkResumableStream() async {
    try {
      final saved = await HostLiveStreamRecovery.loadIfValid();
      if (saved == null || !mounted) return;
      final streamId = saved.streamId?.trim();
      if (streamId == null || streamId.isEmpty) return;
      final meta = await ref.read(liveRemoteProvider).fetchStream(streamId);
      if (meta != null && meta.isLive) {
        setState(() => _resumableSession = saved);
      } else {
        await HostLiveStreamRecovery.clear();
      }
    } finally {
      if (mounted) setState(() => _checkingResume = false);
    }
  }

  Future<void> _resumeSavedStream() async {
    final session = _resumableSession;
    if (session == null) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;
    setState(() => _starting = true);
    try {
      final streamId = session.streamId!.trim();
      final cred = await ref
          .read(trtcRemoteProvider)
          .fetchToken(roomId: streamId, role: 'host');
      _navigatedToRoom = true;
      await context.push(
        '/live/room',
        extra: session.copyWith(trtc: cred, hostUserId: user.id),
      );
      await HostLiveStreamRecovery.clear();
      if (mounted) {
        _resumableSession = null;
        if (context.canPop()) context.pop();
      }
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
  void dispose() {
    _title.dispose();
    final orphan = _orphanStreamId;
    if (orphan != null && !_navigatedToRoom && Env.useMobileAuth) {
      unawaited(
        ref.read(liveRepositoryProvider).endVideoStream(orphan).catchError((_) {}),
      );
    }
    _trtc.dispose();
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
    if (!_trtc.isSupported) {
      if (mounted) {
        setState(
          () => _previewError = 'Kamera yalnızca Android/iOS cihazlarda çalışır',
        );
      }
      return;
    }

    if (mounted) setState(() => _previewLoading = true);
    final ok = await TrtcRoomManager.requestPermissions(video: true);
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
      await _trtc.startPreviewOnly();
      ref.read(liveBeautyProvider.notifier).bindRtc(trtc: _trtc);
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
    if (BotAccountGuard.blockIfBot(
      ref,
      context,
      'canlı yayın başlatma',
      readIsBot: () => ref.read(isBotAccountProvider),
    )) {
      return;
    }
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yayın için giriş yapmalısınız')),
      );
      return;
    }
    if (!_trtc.isSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Canlı yayın yalnızca Android/iOS cihazlarda desteklenir'),
        ),
      );
      return;
    }

    setState(() => _starting = true);
    LiveEventLog.createStart(title: _title.text.trim());
    String? createdStreamId;
    try {
      if (mounted) {
        setState(() => _previewReady = false);
      }

      await _trtc.shutdownForHandoff().timeout(
        const Duration(seconds: 8),
        onTimeout: () {},
      );
      await Future<void>.delayed(const Duration(milliseconds: 350));
      _trtc = TrtcRoomManager();

      var roomId = 'live-${DateTime.now().millisecondsSinceEpoch}';
      if (Env.useMobileAuth) {
        final token = await ref.read(tokenStorageProvider).readAccess();
        if (token == null || token.isEmpty) {
          throw const ApiException(
            'Oturum süresi doldu. Çıkış yapıp tekrar giriş yapın.',
            statusCode: 401,
          );
        }
        final apiCategory = liveStreamApiCategory(
          label: _args.category,
          isFortune: _args.isFortune,
        );
        roomId = await ref.read(liveRepositoryProvider).createVideoStream(
              title: _title.text.trim(),
              description: _args.subtitle ?? _args.category,
              category: apiCategory,
              tags: [_args.fortuneTypeSlug ?? _args.category],
              thumbnailUrl: user.avatarUrl,
              isPrivate: false,
              isImageMode: false,
              backgroundUrl: _backgroundUrl,
            );
        createdStreamId = roomId;
        _orphanStreamId = roomId;
        LiveEventLog.createSuccess(streamId: roomId);
      }

      final TrtcCredentials trtc = await ref
          .read(trtcRemoteProvider)
          .fetchToken(roomId: roomId, role: 'host')
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () => throw const ApiException(
              'Yayın anahtarı alınamadı: sunucu yanıt vermiyor. Lütfen tekrar deneyin.',
            ),
          );

      if (!mounted) {
        await _cleanupOrphanStream();
        return;
      }
      final session = LiveBroadcastSession.demoHost(
        title: _title.text.trim(),
        category: _args.category,
        tags: [_args.fortuneTypeSlug ?? _args.category],
        description: _args.subtitle ?? '',
        streamerName: user.display,
        streamerHandle: user.username,
        avatarUrl: user.avatarUrl,
        backgroundUrl: _backgroundUrl,
        coverImageUrl: _localBackgroundPath ?? _backgroundUrl ?? user.avatarUrl,
      ).copyWith(
        streamId: roomId,
        trtc: trtc,
        hostUserId: user.id,
        initialMicOn: _micOn,
        initialCameraOn: _cameraOn,
        guestLayout: _guestLayout,
      );

      _navigatedToRoom = true;
      _orphanStreamId = null;
      await context.push('/live/room', extra: session);
      if (mounted) {
        _trtc = TrtcRoomManager();
        if (context.canPop()) {
          context.pop();
        }
      }
    } catch (e) {
      LiveEventLog.error('create', e, streamId: createdStreamId);
      if (createdStreamId != null) {
        await _cleanupOrphanStream();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
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
            TrtcLocalVideoView(key: _localPreviewKey, manager: _trtc),
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
                              _trtc.setCameraEnabled(next);
                              if (!mounted) return;
                              setState(() {
                                _cameraOn = next;
                              });
                            },
                          ),
                          const SizedBox(width: 14),
                          _ControlBtn(
                            icon: _micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                            onTap: () {
                              _trtc.setMicEnabled(!_micOn);
                              setState(() => _micOn = !_micOn);
                            },
                          ),
                          const SizedBox(width: 14),
                          _ControlBtn(
                            icon: Icons.cameraswitch_rounded,
                            onTap: _trtc.switchCamera,
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
                      if (_resumableSession != null) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Yarım kalan yayınınız var',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${_resumableSession!.title} · 5 dk içinde devam edebilirsiniz',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 12.5,
                                ),
                              ),
                              const SizedBox(height: 10),
                              FilledButton.icon(
                                onPressed: _starting ? null : _resumeSavedStream,
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text('Yayına devam et'),
                              ),
                            ],
                          ),
                        ),
                      ] else if (_checkingResume)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: LinearProgressIndicator(minHeight: 2),
                        ),
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
      return CanlifalNetworkImage(
        url: _backgroundUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorWidget: const ColoredBox(color: Color(0xFF1A0F32)),
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
