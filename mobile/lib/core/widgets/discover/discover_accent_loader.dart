import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class DiscoverAccentLoader extends StatelessWidget {
  const DiscoverAccentLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppColors.accentPink,
        ),
      ),
    );
  }
}
