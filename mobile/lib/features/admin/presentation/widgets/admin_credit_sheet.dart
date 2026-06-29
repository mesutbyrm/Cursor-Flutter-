import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../pages/admin_panel_page.dart';
import '../providers/admin_panel_providers.dart';

class AdminCreditSheet {
  AdminCreditSheet._();

  static Future<void> show(
    BuildContext context, {
    required WidgetRef ref,
    required Map<String, dynamic> user,
    required AdminCreditKind kind,
  }) async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    var add = true;

    final userId = user['id']?.toString() ?? '';
    final label = user['username']?.toString().trim().isNotEmpty == true
        ? '@${user['username']}'
        : (user['displayName'] ?? user['name'] ?? userId).toString();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    kind == AdminCreditKind.jeton
                        ? 'Jeton yükle / çıkar'
                        : 'CFC yükle / çıkar',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(label, style: TextStyle(color: Colors.grey.shade400)),
                  const SizedBox(height: 16),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('Yükle')),
                      ButtonSegment(value: false, label: Text('Çıkar')),
                    ],
                    selected: {add},
                    onSelectionChanged: (s) => setState(() => add = s.first),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: kind == AdminCreditKind.jeton
                          ? 'Jeton miktarı'
                          : 'CFC miktarı',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Açıklama',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      final amount = int.tryParse(amountCtrl.text.trim()) ?? 0;
                      if (userId.isEmpty || amount < 1) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Geçerli kullanıcı ve miktar girin'),
                          ),
                        );
                        return;
                      }
                      try {
                        await ref.read(adminRemoteProvider).adjustCredits(
                              userId: userId,
                              type: kind == AdminCreditKind.jeton
                                  ? 'jeton'
                                  : 'cfc',
                              amount: amount,
                              add: add,
                              reason: noteCtrl.text.trim(),
                            );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                add
                                    ? '${kind == AdminCreditKind.jeton ? 'Jeton' : 'CFC'} yüklendi'
                                    : '${kind == AdminCreditKind.jeton ? 'Jeton' : 'CFC'} düşüldü',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(ApiException.userMessage(e)),
                            ),
                          );
                        }
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppThemeColors.accentCyan,
                    ),
                    child: const Text('Uygula'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    amountCtrl.dispose();
    noteCtrl.dispose();
  }
}
