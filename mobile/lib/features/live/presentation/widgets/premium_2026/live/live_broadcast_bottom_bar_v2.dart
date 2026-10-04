import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import '../../../../../trtc/presentation/trtc_room_manager.dart';
import '../../broadcast_room/live_camera_control.dart';

/// Premium 2026 Bottom Bar v2 — Geliştirilmiş mesaj, hediye dropdown, kontroller.
class LiveBroadcastBottomBarV2 extends StatefulWidget {
  const LiveBroadcastBottomBarV2({
    super.key,
    required this.chatController,
    required this.onSend,
    required this.isHost,
    this.trtc,
    this.onToggleCamera,
    this.onRtcStateChanged,
    this.onEnd,
    this.onMore,
    this.moreBadgeCount = 0,
    this.onGift,
    this.onTip,
    this.commentsEnabled = true,
    this.onEndPk,
    this.onToggleOpponentMute,
    this.opponentMuted = false,
    this.showPkHostControls = false,
    this.onGuest,
    this.onMulti,
    this.onShare,
    this.onSettings,
    this.multiLayoutActive = false,
    this.guestLabel = 'Misafir',
    this.guestIcon = Icons.person_add_alt_1_rounded,
  });

  final TextEditingController chatController;
  final VoidCallback onSend;
  final bool isHost;
  final TrtcRoomManager? trtc;
  final VoidCallback? onToggleCamera;
  final VoidCallback? onRtcStateChanged;
  final VoidCallback? onEnd;
  final VoidCallback? onMore;
  final int moreBadgeCount;
  final VoidCallback? onGift;
  final VoidCallback? onTip;
  final bool commentsEnabled;
  final VoidCallback? onEndPk;
  final VoidCallback? onToggleOpponentMute;
  final bool opponentMuted;
  final bool showPkHostControls;

  /// Misafir: yayıncıda davet sheet'i, izleyicide misafirlik isteği.
  final VoidCallback? onGuest;

  /// Çoklu yayın düzeni (yalnız yayıncı, tekli yayında).
  final VoidCallback? onMulti;
  final VoidCallback? onShare;

  /// Yayın ayarları (yalnız yayıncı) — çoklu (2x2) düzende «Çoklu/Paylaş» yerine.
  final VoidCallback? onSettings;

  /// Çoklu yayın (2+ kişi) açık mı — alt çubuk düzeni buna göre değişir.
  final bool multiLayoutActive;

  /// Misafir düğmesi etiketi/ikonu — misafirken «Düş».
  final String guestLabel;
  final IconData guestIcon;

  @override
  State<LiveBroadcastBottomBarV2> createState() => _LiveBroadcastBottomBarV2State();
}

class _LiveBroadcastBottomBarV2State extends State<LiveBroadcastBottomBarV2> {
  late FocusNode _messageFocus;
  bool _messageExpanded = false;

  @override
  void initState() {
    super.initState();
    _messageFocus = FocusNode();
    _messageFocus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _messageFocus.removeListener(_onFocusChanged);
    _messageFocus.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _messageExpanded = _messageFocus.hasFocus;
    });
  }

  void _onSendMessage() {
    widget.onSend();
    widget.chatController.clear();
    setState(() => _messageExpanded = false);
    _messageFocus.unfocus();
  }

  List<Widget> _actions() {
    final w = widget;
    final multi = w.multiLayoutActive;
    final items = <Widget>[
      if (w.onGuest != null)
        _ActionIconButton(
          icon: w.guestIcon,
          label: w.guestLabel,
          onTap: w.onGuest!,
        ),
      // Tekli yayında «Çoklu» (yalnız yayıncı).
      if (w.isHost && !multi && w.onMulti != null)
        _ActionIconButton(
          icon: Icons.grid_view_rounded,
          label: 'Çoklu',
          onTap: w.onMulti!,
        ),
      if (w.onGift != null) _GiftButton(onTap: w.onGift!),
      // Tekli: Paylaş · 2x2: Ayarlar (yayıncı) / Paylaş (izleyici).
      if (w.isHost && multi && w.onSettings != null)
        _ActionIconButton(
          icon: Icons.settings_rounded,
          label: 'Ayarlar',
          onTap: w.onSettings!,
        )
      else if (w.onShare != null)
        _ActionIconButton(
          icon: Icons.ios_share_rounded,
          label: 'Paylaş',
          onTap: w.onShare!,
        ),
      if (w.onMore != null)
        _ActionIconButton(
          icon: Icons.more_horiz_rounded,
          label: 'Daha fazla',
          badgeCount: w.moreBadgeCount,
          onTap: w.onMore!,
        ),
    ];
    return [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) const SizedBox(width: 4),
        items[i],
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final hasRtc = widget.trtc != null;
    final rtcChanged = widget.onRtcStateChanged ?? widget.onToggleCamera;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.fromLTRB(10, 8, 10, bottom + 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.42),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Host kontrolleri (Mic, Kamera, Kamera Çevir, Bitir).
              // Yazarken gizlenir: klavyenin üstünde yalnız mesaj satırı kalır.
              if (widget.isHost && hasRtc && !_messageExpanded) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    LiveMicToggleButton(
                      trtc: widget.trtc!,
                      size: 40,
                      onChanged: rtcChanged,
                    ),
                    LiveCameraToggleButton(
                      trtc: widget.trtc!,
                      size: 40,
                      onChanged: rtcChanged,
                    ),
                    LiveCameraSwitchButton(trtc: widget.trtc!),
                    if (widget.showPkHostControls &&
                        widget.onToggleOpponentMute != null)
                      _MiniControl(
                        icon: widget.opponentMuted
                            ? Icons.mic_off_rounded
                            : Icons.mic_rounded,
                        label: widget.opponentMuted ? 'Ses kapalı' : 'Rakip sesi',
                        onTap: widget.onToggleOpponentMute,
                      ),
                    if (widget.showPkHostControls && widget.onEndPk != null)
                      _MiniControl(
                        icon: Icons.flag_rounded,
                        label: 'PK bitir',
                        color: AppThemeColors.liveRed,
                        onTap: widget.onEndPk,
                      ),
                    if (widget.onEnd != null)
                      _MiniControl(
                        icon: Icons.stop_circle_rounded,
                        label: 'Bitir',
                        color: AppThemeColors.liveRed,
                        onTap: widget.onEnd,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Mesaj input + aksiyonlar. Yazarken yalnız input görünür.
              Row(
                children: [
                  Expanded(
                    child: _ExpandableMessageInput(
                      controller: widget.chatController,
                      focusNode: _messageFocus,
                      isExpanded: _messageExpanded,
                      commentsEnabled: widget.commentsEnabled,
                      onSend: _onSendMessage,
                    ),
                  ),
                  if (!_messageExpanded) ...[
                    const SizedBox(width: 6),
                    ..._actions(),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Genişletilebilir mesaj input — fokus olunca expande olur
class _ExpandableMessageInput extends StatelessWidget {
  const _ExpandableMessageInput({
    required this.controller,
    required this.focusNode,
    required this.isExpanded,
    required this.commentsEnabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isExpanded;
  final bool commentsEnabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      height: isExpanded ? 48 : 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(isExpanded ? 12 : 22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: commentsEnabled,
              maxLines: isExpanded ? 2 : 1,
              // Klavyedeki «gönder» de mesajı yollar ve klavyeyi kapatır.
              textInputAction: TextInputAction.send,
              onSubmitted: (_) {
                if (controller.text.trim().isNotEmpty) onSend();
              },
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: commentsEnabled ? 'Yorum yaz...' : 'Yorumlar kapalı',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
          // Send button — sadece mesaj varsa ve expanded ise göster
          if (isExpanded && controller.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: onSend,
                icon: const Icon(Icons.send_rounded, color: Colors.white70),
                iconSize: 20,
                tooltip: 'Gönder',
              ),
            ),
        ],
      ),
    );
  }
}

/// Hediye — doğrudan hediye panelini açar (sahte dropdown listesi kaldırıldı).
class _GiftButton extends StatelessWidget {
  const _GiftButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Hediye',
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF4D8D), Color(0xFFB832FF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF2D7A).withValues(alpha: 0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.card_giftcard_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Hediye',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Aksiyon butonu — ikon + label
class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.35),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF2D7A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.2),
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniControl extends StatelessWidget {
  const _MiniControl({
    required this.icon,
    required this.label,
    this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (color ?? Colors.white).withValues(alpha: 0.15),
              border: Border.all(
                color: (color ?? Colors.white).withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              icon,
              color: color ?? Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
