import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../providers/pending_room_password_provider.dart';
import '../providers/room_password_access_request_provider.dart';
import '../providers/vip_membership_provider.dart';
import '../theme/vip_gold_tokens.dart';

/// Şifreli oda — cam panel + kod girişi. Şifre sunucuda doğrulanır.
Future<bool> showVipLockedRoomSheet(
  BuildContext context,
  WidgetRef ref, {
  required VoiceRoomEntity room,
}) async {
  final unlocked = ref.read(vipUnlockedRoomsProvider);
  if (unlocked.contains(room.apiRoomKey)) return true;

  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ProviderScope(
      parent: ProviderScope.containerOf(context),
      child: _LockedSheet(room: room),
    ),
  );
  final pass = result?.trim() ?? '';
  if (pass.isEmpty) return false;
  ref.read(pendingRoomPasswordProvider.notifier).setPassword(room.apiRoomKey, pass);
  ref.read(vipUnlockedRoomsProvider.notifier).unlock(room.apiRoomKey);
  return true;
}

class _LockedSheet extends ConsumerStatefulWidget {
  const _LockedSheet({required this.room});

  final VoiceRoomEntity room;

  @override
  ConsumerState<_LockedSheet> createState() => _LockedSheetState();
}

class _LockedSheetState extends ConsumerState<_LockedSheet> {
  final _ctrl = TextEditingController();
  String? _error;
  var _requesting = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _ctrl.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Oda şifresi gerekli');
      return;
    }
    Navigator.pop(context, code);
  }

  Future<void> _requestPasswordLearn() async {
    if (_requesting) return;
    final me = ref.read(authControllerProvider).valueOrNull;
    if (me == null) return;
    final roomKey = widget.room.apiRoomKey;
    final can = await RoomPasswordAccessCooldown.canRequest(roomKey, me.id);
    if (!can) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bugün için şifre isteği gönderildi. Gece 00:00 sonrası tekrar deneyin.',
          ),
        ),
      );
      return;
    }
    setState(() => _requesting = true);
    try {
      final dio = ref.read(dioProvider);
      final display = me.displayName?.trim() ?? '';
      final name = display.isNotEmpty ? display : me.username;
      await dio.safePost<dynamic>(
        ApiEndpoints.chatRoomPresence(roomKey),
        data: {
          'action': 'request_password',
          'message': '$name odaya girmek için şifre istiyor',
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'İstek oda sahibine gönderildi. Onaylarsa girebilirsiniz.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Şifre isteği gönderilemedi. Şifreyi oda sahibinden öğrenin.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            decoration: BoxDecoration(
              color: VipGoldTokens.bgDeep.withValues(alpha: 0.96),
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
                  'Bu oda şifre korumalı. Şifreyi bilmeyenler giremez.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.colors.onSurfaceMuted.withValues(alpha: 0.95)),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _ctrl,
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  enableIMEPersonalizedLearning: false,
                  autofillHints: const <String>[],
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
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _requesting ? null : _requestPasswordLearn,
                  child: Text(
                    _requesting ? 'Gönderiliyor…' : 'Şifreyi öğren',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
        ),
      ),
    );
  }
}
