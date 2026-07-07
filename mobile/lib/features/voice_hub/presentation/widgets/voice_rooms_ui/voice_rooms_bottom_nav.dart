import 'package:flutter/material.dart';

import 'voice_rooms_svg_icons.dart';
import 'voice_rooms_ui_tokens.dart';

enum VoiceRoomsNavItem { home, shorts, voice, live, profile }

class VoiceRoomsBottomNav extends StatelessWidget {
  const VoiceRoomsBottomNav({
    super.key,
    required this.active,
    this.onChanged,
  });

  final VoiceRoomsNavItem active;
  final ValueChanged<VoiceRoomsNavItem>? onChanged;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        boxShadow: [
          BoxShadow(
            color: VoiceRoomsUiTokens.purpleGlow.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(8, 8, 8, bottom + 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            iconKey: 'home',
            label: 'Ana Sayfa',
            active: active == VoiceRoomsNavItem.home,
            onTap: () => onChanged?.call(VoiceRoomsNavItem.home),
          ),
          _NavItem(
            iconKey: 'shorts',
            label: 'Shorts',
            active: active == VoiceRoomsNavItem.shorts,
            onTap: () => onChanged?.call(VoiceRoomsNavItem.shorts),
          ),
          _CenterMicButton(
            active: active == VoiceRoomsNavItem.voice,
            onTap: () => onChanged?.call(VoiceRoomsNavItem.voice),
          ),
          _NavItem(
            iconKey: 'live',
            label: 'Canlı Yayınlar',
            active: active == VoiceRoomsNavItem.live,
            onTap: () => onChanged?.call(VoiceRoomsNavItem.live),
          ),
          _NavItem(
            iconKey: 'profile',
            label: 'Profil',
            active: active == VoiceRoomsNavItem.profile,
            onTap: () => onChanged?.call(VoiceRoomsNavItem.profile),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.iconKey,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String iconKey;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? VoiceRoomsUiTokens.purpleGlow
        : VoiceRoomsUiTokens.textMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: VoiceRoomsUiTokens.purpleGlow.withValues(alpha: 0.15),
        child: SizedBox(
          width: 56,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              VoiceRoomsSvgIcons.icon(iconKey, size: 22, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterMicButton extends StatefulWidget {
  const _CenterMicButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  State<_CenterMicButton> createState() => _CenterMicButtonState();
}

class _CenterMicButtonState extends State<_CenterMicButton> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: Transform.translate(
        offset: const Offset(0, -14),
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: VoiceRoomsUiTokens.fabGradient,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                    width: 2,
                  ),
                  boxShadow: VoiceRoomsUiTokens.purpleGlowShadow(blur: 32),
                ),
                child: Center(
                  child: VoiceRoomsSvgIcons.icon('mic', size: 26, color: Colors.white),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sesli Odalar',
                style: TextStyle(
                  color: widget.active
                      ? VoiceRoomsUiTokens.purpleGlow
                      : VoiceRoomsUiTokens.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
