import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/core/theme/app_theme_colors.dart';
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
    if (state == AppLifecycleState.resumed) {
      ref
          .read(psychicVideoControllerProvider(widget.session).notifier)
          .onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final state = ref.watch(psychicVideoControllerProvider(session));
    final ctrl = ref.read(psychicVideoControllerProvider(session).notifier);
    final chat = ref.watch(_psychicSessionChatProvider(session));
    final psychic = session.psychic;

    ref.listen(psychicVideoControllerProvider(session), (prev, next) {
      if (next.timeUpPending && session.isClient) {
        ctrl.handleClientTimeUp(context);
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
            if (state.waitingForTimer)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.55),
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
                            'Falcı hazırlanıyor…',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Süre falcı başlattığında sayılacak',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (state.rtcReady && session.isClient)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 56 + 140 - 28,
                right: 16,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: ctrl.switchCamera,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.cameraswitch_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            if (state.tipThankYouAmount != null && session.isClient)
              Positioned.fill(
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
                                '${state.tipThankYouAmount} jeton',
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
            if (state.tipReceivedAmount != null && !session.isClient)
              Positioned.fill(
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
                            'Danışan size bahşiş gönderdi',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${state.tipReceivedAmount} Jeton',
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
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              left: 12,
              right: 12,
              child: ProfileGlass(
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
                            style: const TextStyle(
                              color: Color(0xFFFFD54F),
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
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: ProfileGlass(
                        padding: const EdgeInsets.all(8),
                        borderRadius: 14,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: state.messages.length,
                          itemBuilder: (_, i) {
                            final msg = state.messages[i];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                '${msg.isMine ? 'Sen' : msg.senderName}: ${msg.text}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: msg.isMine
                                      ? AppThemeColors.accentCyan
                                      : Colors.white70,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: chat,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Mesaj yaz…',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                            filled: true,
                            fillColor: Colors.black.withValues(alpha: 0.45),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
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
                      _ControlBtn(
                        icon: ctrl.micOn
                            ? Icons.mic_rounded
                            : Icons.mic_off_rounded,
                        label: 'Mik',
                        onTap: ctrl.toggleMic,
                      ),
                      _ControlBtn(
                        icon: ctrl.cameraOn
                            ? Icons.videocam_rounded
                            : Icons.videocam_off_rounded,
                        label: 'Kamera',
                        onTap: ctrl.toggleCamera,
                      ),
                      if (!session.isClient)
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
                      if (session.isClient) ...[
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
