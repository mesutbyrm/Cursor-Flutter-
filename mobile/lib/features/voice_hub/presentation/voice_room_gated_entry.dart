import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers/auth_selectors.dart';
import '../../live/domain/entities/voice_room_entity.dart';
import '../../vip_gold/presentation/providers/room_access_providers.dart';
import '../../vip_gold/presentation/widgets/vip_locked_room_sheet.dart';
import 'utils/voice_room_session_utils.dart';
import 'basic/voice_room_page.dart';
import 'widgets/voice_room/voice_room_loading_skeleton.dart';
import 'widgets/voice_room_error_boundary.dart';

/// Sesli oda **tek şifre kapısı**: odaya giden HER yol (liste, derin bağlantı,
/// bildirim, doğrudan `push`) bu widget'tan geçer; oda içeriği kapı geçilmeden
/// hiç oluşturulmaz (mesaj/SSE/TRTC başlamaz).
///
/// Karar listedeki bayrağa DEĞİL sunucuya (`GET verify-password`) dayanır:
/// - oda şifreli değil / sahip-yönetici → doğrudan girer,
/// - geçerli erişim jetonu var → girer,
/// - aksi halde "Bu oda şifrelidir" sayfası (şifre + oda sahibine bildir).
/// Sunucu ayrıca mesaj/SSE/durum/koltuk/TRTC uçlarında kapıyı zorunlu kılar.
class VoiceRoomGatedEntry extends ConsumerStatefulWidget {
  const VoiceRoomGatedEntry({
    super.key,
    required this.room,
    this.prepareSwitch = true,
  });

  final VoiceRoomEntity room;

  /// Derin bağlantıda oda oturumu hazırlanır; liste girişlerinde zaten yapılmıştır.
  final bool prepareSwitch;

  @override
  ConsumerState<VoiceRoomGatedEntry> createState() =>
      _VoiceRoomGatedEntryState();
}

enum _GateResult { open, denied, failed }

class _VoiceRoomGatedEntryState extends ConsumerState<VoiceRoomGatedEntry> {
  var _ready = false;
  _GateResult? _blocked;
  String? _error;

  String get _key => widget.room.apiRoomKey.isNotEmpty
      ? widget.room.apiRoomKey
      : widget.room.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runGate());
  }

  Future<_GateResult> _decide() async {
    final me = ref.read(currentUserIdProvider);
    if (me != null && me.isNotEmpty && widget.room.ownerId == me) {
      return _GateResult.open;
    }
    if (ref.read(roomAccessTokenProvider.notifier).peek(_key) != null) {
      return _GateResult.open;
    }
    try {
      final st = await ref.read(roomAccessRemoteProvider).status(_key);
      if (!st.passwordProtected || st.bypass) return _GateResult.open;
    } on ApiException catch (e) {
      // Eski sunucu (uç yok): kapıyı sunucu kendi uygular; istemci engellemez.
      if (e.statusCode == 404) return _GateResult.open;
      _error = ApiException.userMessage(e);
      return _GateResult.failed;
    } catch (e) {
      _error = ApiException.userMessage(e);
      return _GateResult.failed;
    }
    if (!mounted) return _GateResult.denied;
    final ok = await showVipLockedRoomSheet(context, ref, room: widget.room);
    return ok ? _GateResult.open : _GateResult.denied;
  }

  Future<void> _runGate() async {
    if (!mounted) return;
    setState(() {
      _blocked = null;
      _error = null;
    });
    final result = await _decide();
    if (!mounted) return;
    if (result != _GateResult.open) {
      setState(() => _blocked = result);
      return;
    }
    if (widget.prepareSwitch) {
      await prepareVoiceRoomSwitch(ref, nextLiveKey: _key, source: 'deep_link');
      if (!mounted) return;
    }
    setState(() => _ready = true);
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/voice-rooms');
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocked = _blocked;
    if (blocked != null) {
      final denied = blocked == _GateResult.denied;
      return Scaffold(
        backgroundColor: const Color(0xFF0B0B12),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(denied ? '🔒' : '⚠️', style: const TextStyle(fontSize: 44)),
                  const SizedBox(height: 12),
                  Text(
                    denied
                        ? 'Bu odaya girmek için şifre gerekli'
                        : (_error ?? 'Oda erişimi doğrulanamadı'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _runGate,
                    child: Text(denied ? 'Şifre gir' : 'Tekrar dene'),
                  ),
                  TextButton(onPressed: _leave, child: const Text('Geri dön')),
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (!_ready) {
      return const VoiceRoomLoadingSkeleton();
    }
    return VoiceRoomErrorBoundary(
      roomId: _key,
      child: buildVoiceRoomPage(widget.room),
    );
  }
}
