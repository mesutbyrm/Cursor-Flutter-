import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/economy/presentation/providers/economy_providers.dart';
import '../../../../core/images/canlifal_network_image.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../trtc/presentation/trtc_room_manager.dart';
import '../../domain/pk_room/pk_gift_queue_core.dart';
import '../../domain/pk_room/pk_room_match.dart';
import '../../domain/pk_room/pk_team_layout.dart';
import '../theme/voice_room_tokens.dart';
import 'pk_room_controller.dart';

const _team1Color = VoiceRoomTokens.neonBlue;
const _team2Color = VoiceRoomTokens.neonPink;

/// Sesli odada oda içi PK **modu** — ayrı sayfa DEĞİL.
///
/// Odanın üstüne kompakt bir cam panel ekler (koltuklar yerinde kalır);
/// PK bitince panel kaybolur ve oda eski haline döner. Ayrıca:
///  * odaya girişte / yeniden bağlanınca sunucudan güncel PK'yı alır,
///  * "karşı takım sessiz"i YALNIZCA bu cihazın TRTC oynatmasına uygular,
///  * sonuç / hata bildirimlerini (engellemeyen) SnackBar ile gösterir.
class VoicePkRoomHost extends ConsumerStatefulWidget {
  const VoicePkRoomHost({
    super.key,
    required this.roomKey,
    required this.room,
    required this.canManage,
    required this.micOn,
    required this.micEnabled,
    required this.onToggleMic,
    required this.onGift,
    required this.chatOpen,
    required this.onToggleChat,
    this.trtc,
  });

  /// `voiceRoomLiveProvider` anahtarı (SSE ile aynı anahtar).
  final String roomKey;
  final VoiceRoomEntity room;

  /// Oda sahibi / moderatör — PK'yı bitirebilir (takım kaptanları da bitirebilir).
  final bool canManage;
  final bool micOn;
  final bool micEnabled;
  final VoidCallback onToggleMic;
  final VoidCallback onGift;
  final bool chatOpen;
  final VoidCallback onToggleChat;
  final TrtcRoomManager? trtc;

  @override
  ConsumerState<VoicePkRoomHost> createState() => _VoicePkRoomHostState();
}

class _VoicePkRoomHostState extends ConsumerState<VoicePkRoomHost> {
  TrtcRoomManager? _trtc;

  @override
  void initState() {
    super.initState();
    _trtc = widget.trtc;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final c = ref.read(pkRoomControllerProvider(widget.roomKey).notifier);
      c.attachAlternateKey(_alternateKey());
      unawaited(c.loadCurrent());
    });
  }

  String? _alternateKey() {
    for (final k in [
      widget.room.apiRoomKey,
      widget.room.id,
      widget.room.slug,
    ]) {
      final t = k.trim();
      if (t.isNotEmpty && t != widget.roomKey) return t;
    }
    return null;
  }

  @override
  void didUpdateWidget(covariant VoicePkRoomHost old) {
    super.didUpdateWidget(old);
    if (old.trtc != widget.trtc) {
      old.trtc?.setLocallyMutedRemoteUsers(const {});
      _trtc = widget.trtc;
      _applyMute(ref.read(pkLocalMuteTargetsProvider(widget.roomKey)));
    }
  }

  void _applyMute(Set<String> ids) => _trtc?.setLocallyMutedRemoteUsers(ids);

  @override
  void dispose() {
    // Yerel susturma yalnızca PK'ya özgüdür; oda UI'ı kapanınca temizle.
    _trtc?.setLocallyMutedRemoteUsers(const {});
    super.dispose();
  }

  void _toast(String text) {
    if (!mounted) return;
    final m = ScaffoldMessenger.maybeOf(context);
    m?.hideCurrentSnackBar();
    m?.showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _resultText(PkRoomResult r) {
    final scores = '${r.score1} – ${r.score2}';
    if (r.isDraw || r.winnerSide == null) return 'PK berabere bitti ($scores)';
    final team = r.winnerSide == 1 ? '1. Takım' : '2. Takım';
    final mine = r.mySide == 0
        ? ''
        : (r.mySide == r.winnerSide ? ' — kazandınız 🎉' : ' — kaybettiniz');
    return 'PK bitti: $team kazandı ($scores)$mine';
  }

  @override
  Widget build(BuildContext context) {
    final key = widget.roomKey;

    // Yerel ses: karşı takım kümesi değiştikçe yalnızca BU cihaza uygula.
    ref.listen<Set<String>>(pkLocalMuteTargetsProvider(key), (_, next) {
      _applyMute(next);
    });
    ref.listen<PkRoomResult?>(
      pkRoomControllerProvider(key).select((s) => s.result),
      (_, next) {
        if (next == null) return;
        _toast(_resultText(next));
        ref.read(pkRoomControllerProvider(key).notifier).clearResult();
      },
    );
    ref.listen<String?>(pkRoomControllerProvider(key).select((s) => s.error), (
      _,
      next,
    ) {
      if (next == null || next.isEmpty) return;
      _toast(next);
      ref.read(pkRoomControllerProvider(key).notifier).clearError();
    });

    final visible = ref.watch(
      pkRoomControllerProvider(key).select((s) => s.overlayVisible),
    );
    if (!visible) return const SizedBox.shrink();
    return _PkPanel(
      roomKey: key,
      canManage: widget.canManage,
      micOn: widget.micOn,
      micEnabled: widget.micEnabled,
      onToggleMic: widget.onToggleMic,
      onGift: widget.onGift,
      chatOpen: widget.chatOpen,
      onToggleChat: widget.onToggleChat,
    );
  }
}

class _PkPanel extends ConsumerWidget {
  const _PkPanel({
    required this.roomKey,
    required this.canManage,
    required this.micOn,
    required this.micEnabled,
    required this.onToggleMic,
    required this.onGift,
    required this.chatOpen,
    required this.onToggleChat,
  });

  final String roomKey;
  final bool canManage;
  final bool micOn;
  final bool micEnabled;
  final VoidCallback onToggleMic;
  final VoidCallback onGift;
  final bool chatOpen;
  final VoidCallback onToggleChat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = ref.watch(
      pkRoomControllerProvider(roomKey).select((s) => s.match),
    );
    final muteOpposing = ref.watch(
      pkRoomControllerProvider(roomKey).select((s) => s.muteOpposing),
    );
    final myId = ref.watch(
      authControllerProvider.select((a) => a.valueOrNull?.id),
    );
    if (match == null || !match.phase.showsOverlay) {
      return const SizedBox.shrink();
    }

    final mySide = match.sideOf(myId);
    final isCaptain = match.members.any((m) => m.userId == myId && m.isCaptain);
    final canEnd = canManage || isCaptain;
    final controller = ref.read(pkRoomControllerProvider(roomKey).notifier);
    final size = MediaQuery.sizeOf(context);
    final narrow = size.width < 340;
    // Panel ekranın en çok ~%30'unu kaplar; küçük ekranda içerik sıkışır.
    final maxHeight = (size.height * 0.30).clamp(200.0, 260.0);

    // Yoğun oyun paneli: sistem yazı büyütmesi sınırlanır (taşma/kayma olmasın).
    final clamped = MediaQuery.textScalerOf(
      context,
    ).clamp(minScaleFactor: 1, maxScaleFactor: 1.15);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: clamped),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: RepaintBoundary(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1B0B3A).withValues(alpha: 0.92),
                    const Color(0xFF0A0A1C).withValues(alpha: 0.94),
                  ],
                ),
                border: Border.all(
                  color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.55),
                ),
                boxShadow: [
                  BoxShadow(
                    color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.18),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LayoutBuilder(
                        builder: (context, c) {
                          final center = narrow ? 60.0 : 72.0;
                          final teamW = ((c.maxWidth - center) / 2).clamp(
                            60.0,
                            400.0,
                          );
                          final layout = PkTeamLayout.compute(
                            team1Count: match.team(1).length,
                            team2Count: match.team(2).length,
                            available: teamW,
                          );
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _TeamView(
                                  side: 1,
                                  members: match.team(1),
                                  layout: layout,
                                  mine: mySide == 1,
                                ),
                              ),
                              SizedBox(
                                width: center,
                                child: _CenterTimer(
                                  roomKey: roomKey,
                                  starting: match.phase == PkRoomPhase.starting,
                                  paused: match.phase == PkRoomPhase.paused,
                                ),
                              ),
                              Expanded(
                                child: _TeamView(
                                  side: 2,
                                  members: match.team(2),
                                  layout: layout,
                                  mine: mySide == 2,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      _ScoreBar(score1: match.score1, score2: match.score2),
                      const SizedBox(height: 4),
                      _GiftSlot(roomKey: roomKey),
                      const SizedBox(height: 2),
                      _Controls(
                        narrow: narrow,
                        participant: mySide != 0,
                        micOn: micOn,
                        micEnabled: micEnabled,
                        muteOpposing: muteOpposing,
                        chatOpen: chatOpen,
                        canEnd: canEnd,
                        onToggleMic: onToggleMic,
                        onToggleMute: () =>
                            controller.setMuteOpposing(!muteOpposing),
                        onToggleChat: onToggleChat,
                        onGift: onGift,
                        onEnd: () {
                          HapticFeedback.mediumImpact();
                          unawaited(controller.endNow());
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bir takım: etiket + avatarlar (1–4 oyuncu, dinamik boyut).
class _TeamView extends StatelessWidget {
  const _TeamView({
    required this.side,
    required this.members,
    required this.layout,
    required this.mine,
  });

  final int side;
  final List<PkRoomMember> members;
  final PkTeamLayout layout;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final color = side == 1 ? _team1Color : _team2Color;
    final alignEnd = side == 2;
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          mine ? '$side. TAKIM • SEN' : '$side. TAKIM',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          alignment: alignEnd ? WrapAlignment.end : WrapAlignment.start,
          children: [
            for (final m in members)
              _Member(member: m, color: color, layout: layout),
          ],
        ),
      ],
    );
  }
}

class _Member extends StatelessWidget {
  const _Member({
    required this.member,
    required this.color,
    required this.layout,
  });

  final PkRoomMember member;
  final Color color;
  final PkTeamLayout layout;

  @override
  Widget build(BuildContext context) {
    final size = layout.avatarSize;
    final url = member.avatarUrl?.trim();
    final initial = member.displayName.characters.first.toUpperCase();
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: member.isCaptain ? 2.2 : 1.4),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 6),
        ],
      ),
      child: ClipOval(
        child: url != null && url.isNotEmpty
            ? CanlifalNetworkImage(
                url: url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                thumbnailWidth: 96,
                fadeIn: false,
                errorWidget: _AvatarFallback(initial: initial, color: color),
              )
            : _AvatarFallback(initial: initial, color: color),
      ),
    );
    return Semantics(
      label: member.displayName,
      child: SizedBox(
        width: layout.showNames ? size + 8 : size,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            avatar,
            if (layout.showNames)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  member.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.initial, required this.color});

  final String initial;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color.withValues(alpha: 0.25),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// VS + merkezi sayaç (`PkRoomController.remainingSeconds`).
/// Yalnızca bu widget saniyede bir yeniden çizilir.
class _CenterTimer extends ConsumerWidget {
  const _CenterTimer({
    required this.roomKey,
    required this.starting,
    required this.paused,
  });

  final String roomKey;
  final bool starting;
  final bool paused;

  static String format(int seconds) {
    final s = seconds.clamp(0, 86400);
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remaining = ref.watch(pkRoomRemainingProvider(roomKey));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'VS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        ValueListenableBuilder<int>(
          valueListenable: remaining,
          builder: (context, sec, _) {
            final urgent = !starting && !paused && sec <= 10;
            final text = starting ? '$sec' : format(sec);
            return Semantics(
              label: starting ? 'PK başlıyor $sec' : 'Kalan süre $text',
              child: Text(
                text,
                maxLines: 1,
                style: TextStyle(
                  color: urgent ? _team2Color : VoiceRoomTokens.gold,
                  fontSize: starting ? 24 : 18,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            );
          },
        ),
        Text(
          starting ? 'BAŞLIYOR' : (paused ? 'DURAKLATILDI' : 'PK'),
          maxLines: 1,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

class _ScoreBar extends ConsumerWidget {
  const _ScoreBar({required this.score1, required this.score2});

  final int score1;
  final int score2;

  static String compact(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 10000) return '${(v / 1000).toStringAsFixed(1)}K';
    return '$v';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = economyCurrencyLabel(ref, key: 'jeton');
    final total = score1 + score2;
    final left = total <= 0 ? 0.5 : (score1 / total).clamp(0.08, 0.92);
    return Row(
      children: [
        _ScoreText(text: '${compact(score1)} $label', color: _team1Color),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Expanded(
                    flex: (left * 1000).round(),
                    child: const ColoredBox(color: _team1Color),
                  ),
                  Expanded(
                    flex: ((1 - left) * 1000).round(),
                    child: const ColoredBox(color: _team2Color),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        _ScoreText(
          text: '${compact(score2)} $label',
          color: _team2Color,
          end: true,
        ),
      ],
    );
  }
}

class _ScoreText extends StatelessWidget {
  const _ScoreText({required this.text, required this.color, this.end = false});

  final String text;
  final Color color;
  final bool end;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 52, maxWidth: 92),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: end ? TextAlign.end : TextAlign.start,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

/// Sabit yükseklikli hediye slotu: yerleşim kaymaz, kart fade-in/out olur.
class _GiftSlot extends ConsumerWidget {
  const _GiftSlot({required this.roomKey});

  final String roomKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listenable = ref.watch(pkRoomGiftToastProvider(roomKey));
    return SizedBox(
      height: 34,
      child: ValueListenableBuilder<PkGiftToast?>(
        valueListenable: listenable,
        builder: (context, toast, _) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: toast == null
                ? const Align(
                    key: ValueKey('hint'),
                    child: Text(
                      'Hediye göndererek takımını destekle',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  )
                : _GiftToastCard(key: ValueKey(toast.id), toast: toast),
          );
        },
      ),
    );
  }
}

class _GiftToastCard extends ConsumerWidget {
  const _GiftToastCard({super.key, required this.toast});

  final PkGiftToast toast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = economyCurrencyLabel(ref, key: 'jeton');
    final accent = toast.side == 1
        ? _team1Color
        : toast.side == 2
        ? _team2Color
        : VoiceRoomTokens.gold;
    final url = toast.senderAvatarUrl?.trim();
    final qty = toast.quantity > 1 ? ' x${toast.quantity}' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: accent.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 22,
              height: 22,
              child: url != null && url.isNotEmpty
                  ? CanlifalNetworkImage(
                      url: url,
                      width: 22,
                      height: 22,
                      fit: BoxFit.cover,
                      thumbnailWidth: 64,
                      fadeIn: false,
                      errorWidget: _AvatarFallback(
                        initial: toast.senderName.characters.first
                            .toUpperCase(),
                        color: accent,
                      ),
                    )
                  : _AvatarFallback(
                      initial: toast.senderName.characters.first.toUpperCase(),
                      color: accent,
                    ),
            ),
          ),
          const SizedBox(width: 6),
          const Text('🎁', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '${toast.senderName} • ${toast.giftName}$qty',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${toast.amount} $label',
            maxLines: 1,
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.narrow,
    required this.participant,
    required this.micOn,
    required this.micEnabled,
    required this.muteOpposing,
    required this.chatOpen,
    required this.canEnd,
    required this.onToggleMic,
    required this.onToggleMute,
    required this.onToggleChat,
    required this.onGift,
    required this.onEnd,
  });

  final bool narrow;
  final bool participant;
  final bool micOn;
  final bool micEnabled;
  final bool muteOpposing;
  final bool chatOpen;
  final bool canEnd;
  final VoidCallback onToggleMic;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleChat;
  final VoidCallback onGift;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        // "Karşı Takım" etiketi yalnızca yeterli genişlikte; dar ekranda simge.
        final showLabel = c.maxWidth >= 420;
        return _buildRow(showLabel);
      },
    );
  }

  Widget _buildRow(bool showLabel) {
    final pills = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (participant) ...[
          _Pill(
            icon: micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
            active: micOn,
            enabled: micEnabled,
            tooltip: micOn ? 'Mikrofonu kapat' : 'Mikrofonu aç',
            onTap: onToggleMic,
          ),
          const SizedBox(width: 6),
          _Pill(
            icon: muteOpposing
                ? Icons.volume_off_rounded
                : Icons.volume_up_rounded,
            label: showLabel ? 'Karşı Takım' : null,
            active: !muteOpposing,
            tooltip: muteOpposing
                ? 'Karşı takım sessiz (yalnızca sende)'
                : 'Karşı takımı sustur (yalnızca sende)',
            onTap: onToggleMute,
          ),
          const SizedBox(width: 6),
        ],
        _Pill(
          icon: Icons.chat_bubble_outline_rounded,
          active: chatOpen,
          tooltip: chatOpen ? 'Sohbeti kapat' : 'Sohbet',
          onTap: onToggleChat,
        ),
        const SizedBox(width: 6),
        _Pill(
          icon: Icons.card_giftcard_rounded,
          active: true,
          accent: VoiceRoomTokens.gold,
          tooltip: 'Hediye',
          onTap: onGift,
        ),
      ],
    );
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(fit: BoxFit.scaleDown, child: pills),
          ),
        ),
        if (canEnd)
          TextButton.icon(
            onPressed: onEnd,
            style: TextButton.styleFrom(
              foregroundColor: _team2Color,
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              side: BorderSide(color: _team2Color.withValues(alpha: 0.6)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            icon: const Icon(Icons.stop_circle_outlined, size: 16),
            label: const Text(
              'PK Bitir',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.label,
    this.active = false,
    this.enabled = true,
    this.accent = VoiceRoomTokens.neonPurple,
  });

  final IconData icon;
  final String? label;
  final bool active;
  final bool enabled;
  final Color accent;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? (active ? accent : Colors.white54) : Colors.white24;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(17),
          child: Container(
            height: 34,
            constraints: const BoxConstraints(minWidth: 34),
            padding: EdgeInsets.symmetric(horizontal: label == null ? 8 : 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              color: color.withValues(alpha: active ? 0.16 : 0.08),
              border: Border.all(color: color.withValues(alpha: 0.6)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 17, color: color),
                if (label != null) ...[
                  const SizedBox(width: 5),
                  Text(
                    label!,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
