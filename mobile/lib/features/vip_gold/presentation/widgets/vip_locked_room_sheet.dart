import 'dart:async';

import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../domain/room_access_models.dart';
import '../providers/room_access_providers.dart';
import '../providers/vip_membership_provider.dart';
import '../theme/vip_gold_tokens.dart';

/// Şifreli VIP oda kapısı.
///
/// Şifre ASLA istemcide doğrulanmaz: `POST verify-password` sunucuya gider,
/// kullanıcı başına en fazla 3 deneme hakkı vardır. Başarıda sunucunun verdiği
/// imzalı erişim jetonu [roomAccessTokenProvider]'a yazılır ve join isteğine
/// eklenir. Şifreyi bilmeyen kullanıcı oda sahibinden (yalnızca bir kez) izin
/// isteyebilir; onay da sunucuda tutulur.
///
/// `true` → kullanıcı normal giriş akışına devam edebilir.
Future<bool> showVipLockedRoomSheet(
  BuildContext context,
  WidgetRef ref, {
  required VoiceRoomEntity room,
}) async {
  final unlocked = ref.read(vipUnlockedRoomsProvider);
  if (unlocked.contains(room.apiRoomKey)) return true;

  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ProviderScope(
      parent: ProviderScope.containerOf(context),
      child: VipLockedRoomSheet(room: room),
    ),
  );
  return ok == true;
}

class VipLockedRoomSheet extends ConsumerStatefulWidget {
  const VipLockedRoomSheet({super.key, required this.room});

  final VoiceRoomEntity room;

  @override
  ConsumerState<VipLockedRoomSheet> createState() => _VipLockedRoomSheetState();
}

class _VipLockedRoomSheetState extends ConsumerState<VipLockedRoomSheet> {
  final _ctrl = TextEditingController();
  Timer? _poll;

  var _loading = true;
  var _busy = false;
  var _maxAttempts = 3;
  int? _remaining;
  var _locked = false;
  String? _error;
  String? _info;
  JoinRequestState? _requestState;

  String get _roomKey => widget.room.apiRoomKey.isNotEmpty
      ? widget.room.apiRoomKey
      : widget.room.id;

  @override
  void initState() {
    super.initState();
    unawaited(_loadStatus());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    try {
      final st = await ref.read(roomAccessRemoteProvider).status(_roomKey);
      if (!mounted) return;
      if (!st.passwordProtected || st.bypass) {
        Navigator.pop(context, true);
        return;
      }
      setState(() {
        _maxAttempts = st.maxAttempts;
        _remaining = st.remainingAttempts;
        _locked = st.locked;
        _requestState = parseJoinRequestState(st.joinRequestStatus);
        _loading = false;
      });
      if (_requestState == JoinRequestState.pending) _startPolling();
      if (_requestState == JoinRequestState.accepted) _onApproved();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = ApiException.userMessage(e);
      });
    }
  }

  Future<void> _submit() async {
    if (_busy || _locked) return;
    final code = _ctrl.text;
    if (code.trim().isEmpty) {
      setState(() => _error = 'Oda şifresi gerekli');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res =
          await ref.read(roomAccessRemoteProvider).verifyPassword(_roomKey, code);
      if (!mounted) return;
      switch (res) {
        case PasswordVerified(:final accessToken, :final expiresAt):
          ref
              .read(roomAccessTokenProvider.notifier)
              .set(_roomKey, accessToken, expiresAt);
          Navigator.pop(context, true);
        case PasswordRejected(:final remainingAttempts, :final locked):
          _ctrl.clear();
          setState(() {
            _remaining = remainingAttempts;
            _locked = locked;
            _error = locked
                ? 'Giriş hakkınız kalmadı.'
                : 'Şifre yanlış. $remainingAttempts hakkınız kaldı.';
            _busy = false;
          });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiException.userMessage(e);
        _busy = false;
      });
    }
  }

  Future<void> _requestOwnerPermission() async {
    if (_busy || _requestState != null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final sent = await ref.read(roomAccessRemoteProvider).requestJoin(_roomKey);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _requestState = sent.state ?? JoinRequestState.pending;
        _info = sent.alreadySent
            ? 'Bu oda için zaten bir giriş isteği gönderdiniz.'
            : 'Oda sahibine giriş isteğiniz gönderildi.';
      });
      if (_requestState == JoinRequestState.accepted) {
        _onApproved();
      } else if (_requestState == JoinRequestState.pending) {
        _startPolling();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = ApiException.userMessage(e);
      });
    }
  }

  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) async {
      try {
        final r = await ref.read(roomAccessRemoteProvider).myRequest(_roomKey);
        if (!mounted) return;
        if (r.state == JoinRequestState.accepted && r.allowed) {
          _poll?.cancel();
          _onApproved();
        } else if (r.state == JoinRequestState.rejected) {
          _poll?.cancel();
          setState(() {
            _requestState = JoinRequestState.rejected;
            _info = null;
            _error = 'Oda sahibi giriş isteğinizi reddetti.';
          });
        }
      } catch (_) {
        // Geçici ağ hatası: bir sonraki turda yeniden denenir.
      }
    });
  }

  /// Onay sunucuda tutulur: join isteği normal akışla yapılır, yetkiyi sunucu
  /// "onaylı giriş izni"nden doğrular (istemci bayrağına güvenilmez).
  void _onApproved() {
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final muted = context.colors.onSurfaceMuted.withValues(alpha: 0.95);
    final requestLocked = _requestState != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
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
          child: SingleChildScrollView(
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
                const Text('🔒', style: TextStyle(fontSize: 38)),
                const SizedBox(height: 8),
                const Text(
                  'Şifreli Oda',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.room.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: muted, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  'Bu oda şifrelidir.\nOdaya girmek için oda şifresini girin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted),
                ),
                const SizedBox(height: 16),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else ...[
                  TextField(
                    controller: _ctrl,
                    enabled: !_locked && !_busy,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    enableIMEPersonalizedLearning: false,
                    autofillHints: const <String>[],
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Şifre',
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _locked
                        ? 'Giriş hakkınız kalmadı.'
                        : (_remaining == null || _remaining == _maxAttempts)
                            ? '$_maxAttempts giriş hakkınız bulunmaktadır.'
                            : '$_remaining giriş hakkınız kaldı.',
                    style: TextStyle(
                      fontSize: 12,
                      color: _locked ? Colors.redAccent : muted,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (_info != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _info!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF66E36F),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: (_busy || _locked) ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: VipGoldTokens.goldDeep,
                      ),
                      child: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Odaya Gir',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed:
                        (_busy || requestLocked) ? null : _requestOwnerPermission,
                    icon: const Text('🔑'),
                    label: Text(
                      switch (_requestState) {
                        null => 'Oda Sahibinden İzin İste',
                        JoinRequestState.pending => 'İstek gönderildi — yanıt bekleniyor',
                        JoinRequestState.accepted => 'İzin verildi',
                        JoinRequestState.rejected => 'İstek reddedildi',
                      },
                      style: const TextStyle(fontWeight: FontWeight.w700),
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
