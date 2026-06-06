import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../profile/presentation/widgets/premium/profile_glass.dart';

/// Canlı yayın PK skor çubuğu — web ile aynı sol/sağ puan gösterimi.
class LivePkScoreBar extends StatelessWidget {
  const LivePkScoreBar({
    super.key,
    required this.leftScore,
    required this.rightScore,
    this.status = 'active',
    this.onAccept,
    this.onReject,
    this.onEnd,
    this.isHost = false,
  });

  final int leftScore;
  final int rightScore;
  final String status;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onEnd;
  final bool isHost;

  @override
  Widget build(BuildContext context) {
    final total = (leftScore + rightScore).clamp(1, 999999999);
    final leftFlex = (leftScore / total * 100).round().clamp(10, 90);
    final rightFlex = 100 - leftFlex;

    return ProfileGlass(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: 16,
      blur: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                '$leftScore',
                style: const TextStyle(
                  color: AppColors.accentPink,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                status == 'pending' ? 'PK DAVET' : 'PK',
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                '$rightScore',
                style: const TextStyle(
                  color: AppColors.accentCyan,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Expanded(
                    flex: leftFlex,
                    child: Container(color: AppColors.accentPink),
                  ),
                  Expanded(
                    flex: rightFlex,
                    child: Container(color: AppColors.accentCyan),
                  ),
                ],
              ),
            ),
          ),
          if (status == 'pending' && !isHost) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    child: const Text('Reddet'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: onAccept,
                    child: const Text('Kabul'),
                  ),
                ),
              ],
            ),
          ],
          if (status == 'active' && isHost) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onEnd,
                child: const Text('PK Bitir', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
