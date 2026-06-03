import 'dart:async';

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../live/domain/entities/live_gift_event.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../../domain/pk/pk_battle_mode.dart';
import '../../domain/pk/pk_battle_state.dart';
import '../providers/chat_room_providers.dart';
import '../providers/pk_battle_provider.dart';
import '../providers/voice_gift_combo_tracker.dart';
import '../providers/voice_gift_providers.dart';
import '../theme/voice_room_tokens.dart';
import '../widgets/premium_2026/voice_cosmic_background.dart';
import '../widgets/premium_2026/pk/pk_action_bottom_bar.dart';
import '../widgets/premium_2026/pk/pk_animated_score_bar.dart';
import '../widgets/premium_2026/pk/pk_floating_reactions.dart';
import '../widgets/premium_2026/pk/pk_gift_explosion_flash.dart';
import '../widgets/premium_2026/pk/pk_gift_feed_panel.dart';
import '../widgets/premium_2026/pk/pk_mic_participant_row.dart';
import '../widgets/premium_2026/pk/pk_mode_switcher.dart';
import '../widgets/premium_2026/pk/pk_player_hud_frame.dart';
import '../widgets/premium_2026/pk/pk_team_battle_strip.dart';
import '../widgets/premium_2026/pk/pk_vs_emblem.dart';
import '../widgets/premium_2026/pk/pk_winner_celebration.dart';
import '../widgets/voice_room_gift_sheet.dart';

/// Premium 2026 PK savaş — 1v1, takım, realtime skor, hediye gücü, kazanan FX.
class VoicePkBattlePage extends ConsumerStatefulWidget {
  const VoicePkBattlePage({
    super.key,
    required this.room,
    this.leftUser,
    this.rightUser,
  });

  final VoiceRoomEntity room;
  final ChatRoomPresence? leftUser;
  final ChatRoomPresence? rightUser;

  @override
  ConsumerState<VoicePkBattlePage> createState() => _VoicePkBattlePageState();
}

class _VoicePkBattlePageState extends ConsumerState<VoicePkBattlePage> {
  StreamSubscription<LiveGiftEvent>? _giftSub;
  var _lastGiftSideLeft = true;
  var _chatOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  void _bootstrap() {
    final live = ref.read(voiceRoomLiveProvider(widget.room));
    ref.read(pkBattleProvider.notifier).init(
          room: widget.room,
          presence: live.presence,
          left: widget.leftUser,
          right: widget.rightUser,
        );
    _startGiftRealtime();
  }

  void _startGiftRealtime() {
    final service = ref.read(voiceRoomGiftRealtimeProvider);
    final r = widget.room;
    service.start(
      r.apiRoomKey.isNotEmpty ? r.apiRoomKey : r.id,
      alternateRoomId: r.apiRoomAlternateKey,
    );
    _giftSub?.cancel();
    _giftSub = service.events.listen(_onGiftEvent);
  }

  void _onGiftEvent(LiveGiftEvent raw) {
    if (!mounted) return;
    final event = ref.read(voiceGiftComboTrackerProvider.notifier).enrich(raw);
    final toLeft = ref.read(pkBattleProvider.notifier).giftTargetsLeft(event);
    _lastGiftSideLeft = toLeft;
    ref.read(pkBattleProvider.notifier).applyGift(event, toLeft: toLeft);
  }

  @override
  void dispose() {
    _giftSub?.cancel();
    ref.read(voiceRoomGiftRealtimeProvider).stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(voiceRoomLiveProvider(widget.room));
    final pk = ref.watch(pkBattleProvider);
    final leadingLeft = pk.left.total >= pk.right.total;

    return Scaffold(
      backgroundColor: VoiceRoomTokens.bgDeep,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const VoiceCosmicBackground(),
          PkFloatingReactions(
            burstToken: pk.reactionBurst,
            enabled: pk.isActive,
          ),
          PkGiftExplosionFlash(
            token: pk.reactionBurst,
            toLeft: _lastGiftSideLeft,
          ),
          SafeArea(
            child: Column(
              children: [
                _PkHeader(
                  timer: pk.timerLabel,
                  phase: pk.phase,
                  onBack: () => context.pop(),
                  onMode: pk.isActive
                      ? (m) => ref.read(pkBattleProvider.notifier).setMode(m)
                      : null,
                  mode: pk.mode,
                ),
                Expanded(
                  flex: 3,
                  child: pk.mode == PkBattleMode.team
                      ? _TeamBattleBody(
                          state: pk,
                          leadingLeft: leadingLeft,
                        )
                      : _OneVsOneBody(
                          state: pk,
                          leadingLeft: leadingLeft,
                        ),
                ),
                if (pk.mode == PkBattleMode.team) PkTeamBattleStrip(state: pk),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  child: PkAnimatedScoreBar(state: pk, compact: true),
                ),
                PkMicParticipantRow(presence: live.presence),
                Expanded(
                  flex: 2,
                  child: PkGiftFeedPanel(messages: live.messages),
                ),
                PkActionBottomBar(
                  onSupport: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Destek skora eklendi!')),
                    );
                  },
                  onGift: () => showVoiceRoomGiftPicker(
                    context,
                    ref,
                    room: widget.room,
                  ),
                  onChat: () => setState(() => _chatOpen = !_chatOpen),
                ),
                if (_chatOpen)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: SizedBox(
                      height: 44,
                      child: _PkQuickChat(
                        room: widget.room,
                        onSent: () => setState(() => _chatOpen = false),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          PkWinnerCelebration(
            state: pk,
            onRestart: () => ref.read(pkBattleProvider.notifier).restart(),
            onClose: () => context.pop(),
          ),
        ],
      ),
    );
  }
}

class _PkHeader extends StatelessWidget {
  const _PkHeader({
    required this.timer,
    required this.mode,
    required this.phase,
    required this.onBack,
    required this.onMode,
  });

  final String timer;
  final PkBattleMode mode;
  final PkBattlePhase phase;
  final VoidCallback onBack;
  final ValueChanged<PkBattleMode>? onMode;

  @override
  Widget build(BuildContext context) {
    final liveLabel = phase == PkBattlePhase.finished ? 'BİTTİ' : timer;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              ),
              const Expanded(
                child: Text(
                  'PK Savaşı',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ),
              if (onMode != null)
                PkModeSwitcher(mode: mode, onChanged: onMode!)
              else
                const SizedBox(width: 48),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (phase != PkBattlePhase.finished) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppThemeColors.liveRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      color: AppThemeColors.liveRed,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Text(
                  liveLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PkQuickChat extends ConsumerStatefulWidget {
  const _PkQuickChat({required this.room, required this.onSent});

  final VoiceRoomEntity room;
  final VoidCallback onSent;

  @override
  ConsumerState<_PkQuickChat> createState() => _PkQuickChatState();
}

class _PkQuickChatState extends ConsumerState<_PkQuickChat> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Mesaj yaz…',
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: () async {
            final t = _ctrl.text;
            if (t.trim().isEmpty) return;
            _ctrl.clear();
            await ref
                .read(voiceRoomLiveProvider(widget.room).notifier)
                .sendMessage(t);
            widget.onSent();
          },
          icon: const Icon(Icons.send_rounded),
        ),
      ],
    );
  }
}

class _OneVsOneBody extends StatelessWidget {
  const _OneVsOneBody({
    required this.state,
    required this.leadingLeft,
  });

  final PkBattleState state;
  final bool leadingLeft;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.center,
                    colors: [
                      VoiceRoomTokens.neonPink.withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: PkPlayerHudFrame(
                  user: state.left.leader,
                  accent: VoiceRoomTokens.neonPurple,
                  label: state.left.leader?.displayName ?? 'PLAYER 01',
                  score: state.left.total,
                  isLeading: leadingLeft && state.isActive,
                ),
              ),
            ),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.center,
                    colors: [
                      VoiceRoomTokens.neonBlue.withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: PkPlayerHudFrame(
                  user: state.right.leader,
                  accent: VoiceRoomTokens.neonBlue,
                  label: state.right.leader?.displayName ?? 'PLAYER 02',
                  score: state.right.total,
                  isLeading: !leadingLeft && state.isActive,
                ),
              ),
            ),
          ],
        ),
        const PkVsEmblem(size: 92),
      ],
    );
  }
}

class _TeamBattleBody extends StatelessWidget {
  const _TeamBattleBody({
    required this.state,
    required this.leadingLeft,
  });

  final PkBattleState state;
  final bool leadingLeft;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: _TeamSidePanel(
                members: state.left.members,
                leader: state.left.leader,
                color: VoiceRoomTokens.neonPink,
                isLeading: leadingLeft,
              ),
            ),
            Expanded(
              child: _TeamSidePanel(
                members: state.right.members,
                leader: state.right.leader,
                color: VoiceRoomTokens.neonBlue,
                isLeading: !leadingLeft,
                alignEnd: true,
              ),
            ),
          ],
        ),
        const PkVsEmblem(size: 80),
      ],
    );
  }
}

class _TeamSidePanel extends StatelessWidget {
  const _TeamSidePanel({
    required this.members,
    required this.leader,
    required this.color,
    required this.isLeading,
    this.alignEnd = false,
  });

  final List<ChatRoomPresence> members;
  final ChatRoomPresence? leader;
  final Color color;
  final bool isLeading;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
          end: Alignment.center,
          colors: [color.withValues(alpha: 0.28), Colors.transparent],
        ),
      ),
      child: PkPlayerHudFrame(
        user: leader ?? (members.isNotEmpty ? members.first : null),
        accent: color,
        label: alignEnd ? 'TAKIM B' : 'TAKIM A',
        isLeading: isLeading,
      ),
    );
  }
}

