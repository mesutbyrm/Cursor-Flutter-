import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle_fill_rounded,
                size: 72, color: AppTheme.accent),
            SizedBox(height: 16),
            Text(
              'Canlifal',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppTheme.onBackground,
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(color: AppTheme.accentSecondary),
          ],
        ),
      ),
    );
  }
}
