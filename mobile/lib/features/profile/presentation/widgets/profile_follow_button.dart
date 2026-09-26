import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../shorts/presentation/providers/shorts_providers.dart';
import '../providers/profile_providers.dart';

/// Takip et / Takibi bırak — anında tepki, istek sürerken kilitli,
/// hata olursa eski duruma döner ve kullanıcıya bildirir.
class ProfileFollowButton extends ConsumerStatefulWidget {
  const ProfileFollowButton({
    super.key,
    required this.userId,
    required this.isFollowing,
  });

  final String userId;

  /// Sunucudan gelen son durum.
  final bool isFollowing;

  @override
  ConsumerState<ProfileFollowButton> createState() =>
      _ProfileFollowButtonState();
}

class _ProfileFollowButtonState extends ConsumerState<ProfileFollowButton> {
  late bool _following = widget.isFollowing;
  var _busy = false;

  @override
  void didUpdateWidget(covariant ProfileFollowButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_busy && oldWidget.isFollowing != widget.isFollowing) {
      _following = widget.isFollowing;
    }
  }

  Future<void> _toggle() async {
    if (_busy) return;
    final next = !_following;
    HapticFeedback.selectionClick();
    setState(() {
      _busy = true;
      _following = next;
    });
    try {
      final repo = ref.read(profileRepositoryProvider);
      next
          ? await repo.follow(widget.userId)
          : await repo.unfollow(widget.userId);
      ref.invalidate(userProfileProvider(widget.userId));
      ref.invalidate(shortVideoProfileStatsProvider(widget.userId));
    } catch (e) {
      if (!mounted) return;
      setState(() => _following = !next);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ApiException.userMessage(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _following ? 'Takibi bırak' : 'Takip et';
    final child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: Row(
        key: ValueKey(_following),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _following ? Icons.check_rounded : Icons.person_add_alt_1_rounded,
            size: 18,
          ),
          const SizedBox(width: 6),
          Flexible(child: Text(label, maxLines: 1)),
        ],
      ),
    );
    const style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size.fromHeight(46)),
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 10)),
    );

    return Semantics(
      button: true,
      toggled: _following,
      label: _following ? 'Takip ediliyor. Takibi bırak' : 'Takip et',
      excludeSemantics: true,
      onTap: _busy ? null : _toggle,
      child: _following
          ? FilledButton.tonal(
              style: style,
              onPressed: _busy ? null : _toggle,
              child: child,
            )
          : FilledButton(
              style: style,
              onPressed: _busy ? null : _toggle,
              child: child,
            ),
    );
  }
}
