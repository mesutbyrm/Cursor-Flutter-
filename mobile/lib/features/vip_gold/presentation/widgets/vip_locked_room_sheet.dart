import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../live/domain/entities/voice_room_entity.dart';
import '../../domain/voice_room_access.dart';
import '../providers/vip_membership_provider.dart';
import '../theme/vip_gold_tokens.dart';

/// Şifreli oda — cam panel + kod girişi.
Future<bool> showVipLockedRoomSheet(
  BuildContext context,
  WidgetRef ref, {
  required VoiceRoomEntity room,
}) async {
  final unlocked = ref.read(vipUnlockedRoomsProvider);
  if (unlocked.contains(room.apiRoomKey)) return true;

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _LockedSheet(room: room),
  );
  if (result == true) {
    ref.read(vipUnlockedRoomsProvider.notifier).unlock(room.apiRoomKey);
  }
  return result == true;
}

class _LockedSheet extends StatefulWidget {
  const _LockedSheet({required this.room});

  final VoiceRoomEntity room;

  @override
  State<_LockedSheet> createState() => _LockedSheetState();
}

class _LockedSheetState extends State<_LockedSheet> {
  final _ctrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _ctrl.text.trim();
    if (code == widget.room.demoPassword) {
      Navigator.pop(context, true);
      return;
    }
    setState(() => _error = 'Geçersiz şifre');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  VipGoldTokens.goldDeep.withValues(alpha: 0.35),
                  VipGoldTokens.bgDeep,
                ],
              ),
              border: Border(
                top: BorderSide(color: VipGoldTokens.goldMid.withValues(alpha: 0.5)),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                const Icon(Icons.lock_rounded, color: VipGoldTokens.goldMid, size: 40),
                const SizedBox(height: 12),
                Text(
                  widget.room.displayTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Bu oda şifre korumalı. Davet kodunu gir.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.colors.onSurfaceMuted.withValues(alpha: 0.95)),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _ctrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Oda şifresi',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    errorText: _error,
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: VipGoldTokens.goldDeep,
                    ),
                    child: const Text(
                      'Odaya Gir',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
