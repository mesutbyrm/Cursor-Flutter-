import 'dart:io';

import 'package:flutter/material.dart';

/// Video kapak önerileri — yatay şerit; seçilen dosya video küçük resmi olur.
class StudioCoverPicker extends StatelessWidget {
  const StudioCoverPicker({
    super.key,
    required this.candidates,
    required this.selectedPath,
    required this.onSelected,
    this.loading = false,
    this.onGenerate,
  });

  final List<String> candidates;
  final String? selectedPath;
  final ValueChanged<String> onSelected;
  final bool loading;
  final VoidCallback? onGenerate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text(
              'Kapak önerileri',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            if (onGenerate != null)
              TextButton.icon(
                onPressed: loading ? null : onGenerate,
                icon: loading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Yenile'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (loading && candidates.isEmpty)
          const SizedBox(
            height: 80,
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (candidates.isEmpty)
          Text(
            'Videodan kapak kareleri oluşturuluyor…',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          )
        else
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: candidates.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final path = candidates[i];
                final selected = selectedPath == path;
                return GestureDetector(
                  onTap: () => onSelected(path),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFFFFD54F)
                            : Colors.white24,
                        width: selected ? 2.5 : 1,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: const Color(0xFFFFD54F)
                                    .withValues(alpha: 0.35),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          File(path),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const ColoredBox(
                            color: Color(0xFF2A2A35),
                            child: Icon(Icons.broken_image_outlined,
                                color: Colors.white38),
                          ),
                        ),
                        if (selected)
                          const Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFFFFD54F),
                                size: 18,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 4),
        Text(
          'Bir kapak seçin — trend videolarda bu görsel kullanılır.',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}
