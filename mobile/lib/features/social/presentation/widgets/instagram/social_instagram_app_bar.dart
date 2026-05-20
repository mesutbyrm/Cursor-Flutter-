import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_design.dart';

/// Instagram tarzı üst çubuk — site renkleri (pembe/mor gradyan logo).
class SocialInstagramAppBar extends StatelessWidget {
  const SocialInstagramAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Container(
      padding: EdgeInsets.fromLTRB(16, top + 8, 12, 10),
      decoration: BoxDecoration(
        color: AppDesign.bgBase.withValues(alpha: 0.98),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                AppDesign.heroGradient.createShader(bounds),
            child: const Text(
              'Canlifal',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
                color: Colors.white,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add_box_outlined, size: 26),
            color: AppDesign.textPrimary,
            tooltip: 'Yeni paylaşım',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Paylaşım yakında')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border_rounded, size: 26),
            color: AppDesign.textPrimary,
            tooltip: 'Bildirimler',
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.send_outlined, size: 24),
            color: AppDesign.textPrimary,
            tooltip: 'Mesajlar',
            onPressed: () => context.go('/messages'),
          ),
        ],
      ),
    );
  }
}
