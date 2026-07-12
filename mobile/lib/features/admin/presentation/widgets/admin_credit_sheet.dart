import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/admin_user_util.dart';
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
    final normalized = normalizeAdminUserMap(user);
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    var add = true;
    var busy = false;

    final userId = resolveAdminUserId(normalized);
    final label = normalized['username']?.toString().trim().isNotEmpty == true
        ? '@${normalized['username']}'
        : (normalized['displayName'] ?? normalized['name'] ?? userId).toString();
    final messenger = ScaffoldMessenger.of(context);

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
            Future<void> apply() async {
              if (busy) return;
              final amount = int.tryParse(amountCtrl.text.trim()) ?? 0;
              if (userId.isEmpty) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Kullanıcı kimliği bulunamadı — aramadan tekrar seçin.',
                    ),
                  ),
                );
                return;
              }
              if (amount < 1) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Geçerli bir miktar girin')),
                );
                return;
              }

              setState(() => busy = true);
              HapticFeedback.mediumImpact();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    add
                        ? '${kind == AdminCreditKind.jeton ? 'Jeton' : 'CFC'} yükleniyor…'
                        : '${kind == AdminCreditKind.jeton ? 'Jeton' : 'CFC'} düşülüyor…',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );

              try {
                await ref.read(adminRemoteProvider).adjustCredits(
                      userId: userId,
                      type: kind == AdminCreditKind.jeton ? 'jeton' : 'cfc',
                      amount: amount,
                      add: add,
                      reason: noteCtrl.text.trim(),
                    );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      add
                          ? '${kind == AdminCreditKind.jeton ? 'Jeton' : 'CFC'} yüklendi ($amount)'
                          : '${kind == AdminCreditKind.jeton ? 'Jeton' : 'CFC'} düşüldü ($amount)',
                    ),
                    backgroundColor: Colors.green.shade800,
                  ),
                );
              } catch (e) {
                if (ctx.mounted) {
                  setState(() => busy = false);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(ApiException.userMessage(e)),
                      backgroundColor: Colors.red.shade800,
                    ),
                  );
                }
              }
            }

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
                  if (userId.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Uyarı: kullanıcı kimliği eksik — işlem başarısız olabilir.',
                        style: TextStyle(color: Colors.orange.shade400, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 16),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('Yükle')),
                      ButtonSegment(value: false, label: Text('Çıkar')),
                    ],
                    selected: {add},
                    onSelectionChanged: busy
                        ? null
                        : (s) => setState(() => add = s.first),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    enabled: !busy,
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
                    enabled: !busy,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Açıklama',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: busy ? null : apply,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppThemeColors.accentCyan,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Uygula'),
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
