import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../data/fortune_catalog.dart';
import '../widgets/fortune_hub_type_card.dart';
import '../widgets/fortune_mystic_background.dart';

/// Tüm fal türleri — hub grid ile aynı kart stili.
class FortuneTypesAllPage extends StatelessWidget {
  const FortuneTypesAllPage({super.key});

  @override
  Widget build(BuildContext context) {
    final types = FortuneCatalog.types;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Fal Türleri',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: FortuneMysticBackground(
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.02,
          ),
          itemCount: types.length,
          itemBuilder: (context, i) {
            final type = types[i];
            return FortuneHubTypeCard(
              type: type,
              subtitle: type.description,
              onTap: () => context.push('/fortune/${type.slug}'),
            );
          },
        ),
      ),
    );
  }
}
