import '../../domain/entities/psychic_room_entity.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/economy/presentation/providers/economy_providers.dart';
import 'package:canlifal_social/features/live_psychics/presentation/widgets/psychic_close_dialog.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_entity.dart';
import 'package:canlifal_social/features/live_psychics/presentation/controllers/psychic_video_controller.dart';
import 'package:canlifal_social/features/profile/presentation/widgets/premium/profile_glass.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/psychic_peer_left_provider.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/psychic_session_cancel_signal.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/psychic_session_ended_provider.dart';
import '../widgets/psychic_video_call_layer.dart';

final _psychicSessionChatProvider =
    StateProvider.autoDispose.family<TextEditingController, PsychicSessionEntity>(
  (ref, _) => TextEditingController(),
);

/// Canlı fal video oturumu — Tencent TRTC + süre + sohbet.
class PsychicVideoSessionScreen extends ConsumerStatefulWidget {
  const PsychicVideoSessionScreen({super.key, required this.session});

  final PsychicSessionEntity session;

  @override
  ConsumerState<PsychicVideoSessionScreen> createState() =>
      _PsychicVideoSessionScreenState();
}

class _PsychicVideoSessionScreenState extends ConsumerState<PsychicVideoSessionScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = ref.read(psychicVideoControllerProvider(widget.session).notifier);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      ctrl.onAppPaused();
      return;
    }
    if (state == AppLifecycleState.resumed) {
      ctrl.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final state = ref.watch(psychicVideoControllerProvider(session));
    final ctrl = ref.read(psychicVideoControllerProvider(session).notifier);
    final chat = ref.watch(_psychicSessionChatProvider(session));
    final psychic = session.psychic;
    final jetonLabel = economyCurrencyLabel(ref, key: 'jeton');
    final clientPeerLive = session.isClient &&
        (state.remoteCamera.values.any((v) => v) ||
            state.remoteMicrophone.values.any((v) => v));

    ref.listen(psychicVideoControllerProvider(session), (prev, next) {
      if (next.timeUpPending && session.isClient) {
        ctrl.handleClientTimeUp(context);
      }
      if (next.lowTimeWarningPending &&
          prev?.lowTimeWarningPending != true &&
          session.isClient &&
          context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Süreniz azalıyor — ${next.timerLabel} kaldı',
            ),
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'Uzat',
              onPressed: () async {
                final choice = await ctrl.openExtendSheet(context);
                if (!context.mounted || choice == null) return;
                await ctrl.extendSession(choice);
              },
            ),
          ),
        );
      }
      if (next.leaving && prev?.leaving != true && context.mounted) {
        final peerMsg = ref.read(psychicPeerLeftProvider)?.message;
        if (peerMsg != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(peerMsg)),
          );
          ref.read(psychicPeerLeftProvider.notifier).clear();
        }
        if (ref.read(psychicSessionEndedProvider) == null) {
          ref.read(psychicSessionEndedProvider.notifier).state =
              PsychicSessionEndedEvent(
            sessionId: session.sessionId,
            tellerId: session.psychic.id,
            tellerName: session.psychic.name,
            durationMinutes: session.durationMinutes,
            totalJeton: session.totalJeton,
            tipsJeton: !session.isClient && state.sessionTipsTotal > 0
                ? state.sessionTipsTotal
                : null,
            isTeller: !session.isClient,
            promptReview: session.isClient,
            navigateAfter: true,
            message: peerMsg,
          );
        }
      }
    });

    ref.listen<PsychicSessionCancelEvent?>(psychicSessionCancelSignalProvider,
        (prev, event) {
      if (event == null || event.sessionId != session.sessionId) return;
      if (prev?.seq == event.seq) return;
      final leaving = ref.read(psychicVideoControllerProvider(session)).leaving;
      if (leaving) return;
      final msg = session.isClient
          ? 'Falcı görüşmeyi sonlandırdı.'
          : 'Kullanıcı görüşmeyi sonlandırdı.';
      unawaited(ctrl.leave(silent: true, peerEndedMessage: msg));
    });

    ref.listen<PsychicPeerLeftEvent?>(psychicPeerLeftProvider, (prev, next) {
      if (next == null || next.sessionId != session.sessionId) return;
      if (prev?.seq == next.seq) return;
      if (ref.read(psychicVideoControllerProvider(session)).leaving) return;
      unawaited(ctrl.leave(silent: true, peerEndedMessage: next.message));
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await showPsychicCloseDialog(
          context,
          title: 'Seansı kapat?',
          message: session.isClient
              ? 'Canlı fal oturumundan çıkmak istediğinize emin misiniz?'
              : 'Seansı sonlandırmak istediğinize emin misiniz?',
          confirmLabel: 'Kapat',
        );
        if (ok && context.mounted) {
          await ctrl.leave();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: PsychicVideoCallLayer(
                session: session,
                state: state,
                ctrl: ctrl,
              ),
            ),
            // Danışan onay istemi hazır değilken bekleme perdesi (A/V gizli).
            if (!state.timerStarted &&
                !(state.timerStartPrompt && session.isClient))
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.75),
                  child: Center(
                    child: ProfileGlass(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      borderRadius: 20,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            session.isClient
                                ? (clientPeerLive
                                    ? 'Falcı bağlandı. Görüşme başlıyor…'
                                    : 'Falcıya bağlanılıyor…')
                                : (state.timerStartRequestSent
                                    ? 'Görüşme başlıyor…'
                                    : 'Kullanıcı bekleniyor…'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            session.isClient
                                ? 'İki taraf da bağlanınca görüntü, ses ve süre aynı anda başlar.'
                                : 'Kullanıcı bağlanınca görüntü, ses ve süre aynı anda başlar.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            // Danışan: falcı süre başlatma isteği gönderdi → onay istemi.
            if (state.timerStartPrompt && session.isClient && !state.timerStarted)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.8),
                  child: Center(
                    child: ProfileGlass(
                      padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
                      borderRadius: 24,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('⏱️', style: TextStyle(fontSize: 36)),
                          const SizedBox(height: 10),
                          Text(
                            '${psychic.name} görüşmeye hazır',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Onayladığınızda görüntü ve ses açılır, süre ve ücret başlar.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () => unawaited(ctrl.acceptTimerStart()),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppThemeColors.accentPurple,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Görüşmeyi Başlat',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: ctrl.dismissTimerStartPrompt,
                            child: const Text('Biraz bekle'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            // Kamera çevirme — hem falcı hem danışan (ön ↔ arka).
            if (state.rtcReady && state.timerStarted)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 72 + 140 - 32,
                right: 14,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: ctrl.switchCamera,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(9),
                      child: Icon(
                        Icons.cameraswitch_rounded,
                        color: Colors.white,
                        size: 24,
                        semanticLabel: 'Kamerayı çevir',
                      ),
                    ),
                  ),
                ),
              ),
            if (state.tipThankYouAmount != null && session.isClient)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: ctrl.dismissTipThankYouOverlay,
                  child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.45),
                  child: Center(
                    child: ProfileGlass(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                      borderRadius: 24,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🙏', style: TextStyle(fontSize: 36)),
                          const SizedBox(height: 10),
                          Text(
                            psychic.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bahşişiniz başarıyla gönderildi.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          if (state.tipThankYouAmount != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '${state.tipThankYouAmount} $jetonLabel',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                ),
              ),
            if (state.tipReceivedAmount != null && !session.isClient)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: ctrl.dismissTipReceivedOverlay,
                  child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.45),
                  child: Center(
                    child: ProfileGlass(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                      borderRadius: 24,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🎁', style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 10),
                          Text(
                            state.tipReceivedFrom != null &&
                                    state.tipReceivedFrom!.trim().isNotEmpty
                                ? '${state.tipReceivedFrom} size bahşiş attı'
                                : 'Danışan size bahşiş attı',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${state.tipReceivedAmount} $jetonLabel',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFFFD54F),
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                ),
              ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.sseFailed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: const Color(0xFF5C1A1A),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () => unawaited(ctrl.retryRoomSse()),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.wifi_off_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Canlı bağlantı koptu — dokunarak yenile',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.refresh_rounded,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ProfileGlass(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                borderRadius: 16,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            psychic.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            state.timerStarted
                                ? state.timerLabel
                                : 'Süre bekleniyor',
                            style: TextStyle(
                              color: state.timerStarted &&
                                      state.remaining.inSeconds <= 120
                                  ? const Color(0xFFFF5252)
                                  : const Color(0xFFFFD54F),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        final ok = await showPsychicCloseDialog(
                          context,
                          title: 'Seansı kapat?',
                          message: 'Oturumu sonlandırmak istiyor musunuz?',
                          confirmLabel: 'Kapat',
                        );
                        if (ok && context.mounted) {
                          await ctrl.leave();
                        }
                      },
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
                ],
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: MediaQuery.paddingOf(context).bottom + 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.messages.isNotEmpty)
                    ConstrainedBox(
                      // Ekran yüksekliğine göre — küçük telefonda da tablette de okunur.
                      constraints: BoxConstraints(
                        maxHeight: (MediaQuery.sizeOf(context).height * 0.26)
                            .clamp(140.0, 260.0),
                      ),
                      // Şeffaf sohbet: kutu yok, kamera / arka plan görünür.
                      // Üst kenar yumuşakça kaybolur; yazılar gölgeyle okunur.
                      child: ShaderMask(
                        shaderCallback: (rect) => const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.white],
                          stops: [0, 0.22],
                        ).createShader(rect),
                        blendMode: BlendMode.dstIn,
                        child: ListView.builder(
                          // En yeni mesaj her zaman altta ve görünür.
                          reverse: true,
                          padding: EdgeInsets.zero,
                          itemCount: state.messages.length,
                          itemBuilder: (_, i) => _PsychicChatLine(
                            msg: state.messages[state.messages.length - 1 - i],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: chat,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Mesaj yaz…',
                            hintStyle: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          onSubmitted: (_) {
                            ctrl.sendChat(chat.text);
                            chat.clear();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: state.sendingChat
                            ? null
                            : () {
                                ctrl.sendChat(chat.text);
                                chat.clear();
                              },
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (state.timerStarted) ...[
                        _ControlBtn(
                          icon: ctrl.micOn
                              ? Icons.mic_rounded
                              : Icons.mic_off_rounded,
                          label: 'Mikrofon',
                          onTap: ctrl.toggleMic,
                        ),
                        _ControlBtn(
                          icon: ctrl.cameraOn
                              ? Icons.videocam_rounded
                              : Icons.videocam_off_rounded,
                          label: 'Kamera',
                          onTap: ctrl.toggleCamera,
                        ),
                      ],
                      if (!session.isClient && state.timerStarted)
                        _ControlBtn(
                          icon: Icons.schedule_rounded,
                          label: 'Süre ekle',
                          onTap: () async {
                            final choice = await ctrl.openExtendSheet(context);
                            if (choice == null || !context.mounted) return;
                            final ok = await ctrl.tellerAddTime(choice);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok
                                      ? '${choice.minutes} dakika eklendi'
                                      : 'Süre eklenemedi',
                                ),
                              ),
                            );
                          },
                        ),
                      if (session.isClient && state.timerStarted) ...[
                        _ControlBtn(
                          icon: Icons.card_giftcard_rounded,
                          label: 'Bahşiş',
                          onTap: () async {
                            final amount = await ctrl.openTipSheet(context);
                            if (amount != null) {
                              final ok = await ctrl.sendTip(amount);
                              if (!ok && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Bahşiş gönderilemedi'),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        _ControlBtn(
                          icon: Icons.schedule_rounded,
                          label: 'Uzat',
                          onTap: () async {
                            final choice = await ctrl.openExtendSheet(context);
                            if (choice == null || !context.mounted) return;
                            final ok = await ctrl.extendSession(choice);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok
                                      ? '${choice.minutes} dakika eklendi'
                                      : 'Süre uzatılamadı',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
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

class _ControlBtn extends StatelessWidget {
  const _ControlBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.white.withValues(alpha: 0.12),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
      ],
    );
  }
}


/// Şeffaf sohbet satırı: ad renkli, metin beyaz; arka plan yok, gölge var.
class _PsychicChatLine extends StatelessWidget {
  const _PsychicChatLine({required this.msg});

  final PsychicChatMessage msg;

  static const _shadows = [
    Shadow(color: Color(0xCC000000), blurRadius: 6),
    Shadow(color: Color(0x99000000), offset: Offset(0, 1), blurRadius: 2),
  ];

  @override
  Widget build(BuildContext context) {
    if (msg.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          msg.text,
          style: const TextStyle(
            fontSize: 15,
            height: 1.3,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
            color: Color(0xFFFFD54F),
            shadows: _shadows,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${msg.isMine ? 'Sen' : msg.senderName}  ',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: msg.isMine
                    ? AppThemeColors.accentCyan
                    : const Color(0xFFFFD54F),
              ),
            ),
            TextSpan(text: msg.text),
          ],
        ),
        style: const TextStyle(
          fontSize: 16,
          height: 1.35,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
          color: Colors.white,
          shadows: _shadows,
        ),
      ),
    );
  }
}
