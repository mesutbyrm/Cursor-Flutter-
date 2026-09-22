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
    this.onGift,
    this.onTip,
    this.commentsEnabled = true,
  });

  final TextEditingController chatController;
  final VoidCallback onSend;
  final bool isHost;
  final TrtcRoomManager? trtc;
  final VoidCallback? onToggleCamera;
  final VoidCallback? onRtcStateChanged;
  final VoidCallback? onEnd;
  final VoidCallback? onMore;
  final VoidCallback? onGift;
  final VoidCallback? onTip;
  final bool commentsEnabled;

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
              // Host kontrolleri (Mic, Kamera, Kamera Çevir, Bitir)
              if (widget.isHost && hasRtc) ...[
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

              // Mesaj input + Kontroller
              Row(
                children: [
                  // Mesaj input (genişletilebilir)
                  Expanded(
                    child: _ExpandableMessageInput(
                      controller: widget.chatController,
                      focusNode: _messageFocus,
                      isExpanded: _messageExpanded,
                      commentsEnabled: widget.commentsEnabled,
                      onSend: _onSendMessage,
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Hediye dropdown (sola doğru açılır)
                  if (widget.onGift != null)
                    _GiftDropdownButton(onGift: widget.onGift!),

                  // Daha fazla (ayarlar)
                  if (widget.onMore != null)
                    _ActionIconButton(
                      icon: Icons.apps_rounded,
                      label: 'Daha fazla',
                      onTap: widget.onMore,
                    ),
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: commentsEnabled ? 'Mesajını yaz...' : 'Yorumlar kapalı',
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

/// Hediye dropdown — sola doğru açılır, hediye seçilebilir
class _GiftDropdownButton extends StatefulWidget {
  const _GiftDropdownButton({required this.onGift});

  final VoidCallback onGift;

  @override
  State<_GiftDropdownButton> createState() => _GiftDropdownButtonState();
}

class _GiftDropdownButtonState extends State<_GiftDropdownButton> {
  bool _showDropdown = false;

  // Mock hediye listesi — backend'den gelecek
  final List<Map<String, dynamic>> gifts = [
    {'name': '❤️', 'label': 'Kalp', 'price': 10},
    {'name': '💎', 'label': 'Elmas', 'price': 50},
    {'name': '🌹', 'label': 'Gül', 'price': 20},
    {'name': '⭐', 'label': 'Yıldız', 'price': 30},
    {'name': '🎁', 'label': 'Hediye', 'price': 100},
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        // Gift button
        GestureDetector(
          onTap: () => setState(() => _showDropdown = !_showDropdown),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFB388FF),
                      Color(0xFF7C4DFF),
                      Color(0xFF5E35B1)
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C4DFF).withValues(alpha: 0.55),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: Colors.white,
                  size: 26,
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

        // Dropdown menu — sola doğru açılır
        if (_showDropdown)
          Positioned(
            right: 0,
            top: 50,
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: gifts
                        .map(
                          (gift) => GestureDetector(
                            onTap: () {
                              widget.onGift();
                              setState(() => _showDropdown = false);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    gift['name'],
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${gift['label']} (${gift['price']})',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Aksiyon butonu — ikon + label
class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.35),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
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
