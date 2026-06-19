import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/fortune_type_entity.dart';
import '../services/fortune_reading_coordinator.dart';
import '../widgets/fortune_mystic_background.dart';

/// Eski oturum rotası — doğrudan fal sonucuna yönlendirir (falına bak ekranı kaldırıldı).
class FortuneSessionPage extends ConsumerStatefulWidget {
  const FortuneSessionPage({super.key, required this.type});

  final FortuneTypeEntity type;

  @override
  ConsumerState<FortuneSessionPage> createState() => _FortuneSessionPageState();
}

class _FortuneSessionPageState extends ConsumerState<FortuneSessionPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  Future<void> _open() async {
    if (!mounted) return;
    await FortuneReadingCoordinator.openReading(
      context: context,
      ref: ref,
      type: widget.type,
      replaceCurrentRoute: true,
    );
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FortuneMysticBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: widget.type.accent),
              const SizedBox(height: 16),
              Text(
                '${widget.type.title} hazırlanıyor…',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
