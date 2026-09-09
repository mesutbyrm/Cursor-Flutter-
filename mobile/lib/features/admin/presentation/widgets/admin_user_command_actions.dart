import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../live/data/pk/pk_room_remote_datasource.dart';
import '../widgets/admin_payment_reject_sheet.dart';
import '../../domain/admin_payment_review.dart';
import '../../domain/admin_site_animation.dart';
import '../../domain/admin_user_extended_data.dart';
import '../providers/admin_panel_providers.dart';
import '../providers/admin_site_animation_providers.dart';
import '../providers/staff_access_provider.dart';

/// Komuta merkezi eylem diyalogları (Faz 2–3).
abstract final class AdminUserCommandActions {
  static Future<void> showPsychicSheet(
    BuildContext context,
    WidgetRef ref, {
    required String userId,
    required String displayName,
    AdminLiveTellerSummary? teller,
    required VoidCallback onDone,
  }) async {
    final noteCtrl = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.viewInsetsOf(ctx).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Canlı falcı — $displayName',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              teller != null
                  ? 'Kayıt: ${teller.tellerId} · ${teller.status ?? "—"}'
                  : 'Henüz falcı kaydı yok — oluşturulabilir.',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Not (onay/red)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            if (teller == null)
              FilledButton(
                onPressed: () async {
                  try {
                    await ref.read(adminRemoteProvider).createLiveTeller(
                          userId: userId,
                          displayName: displayName,
                        );
                    if (ctx.mounted) Navigator.pop(ctx);
                    onDone();
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text(ApiException.userMessage(e))),
                      );
                    }
                  }
                },
                child: const Text('Falcı kaydı oluştur'),
              ),
            if (teller != null) ...[
              FilledButton(
                onPressed: () => _approve(ctx, ref, teller.tellerId, 'approve',
                    noteCtrl.text, onDone),
                child: const Text('Onayla'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => _approve(ctx, ref, teller.tellerId, 'reject',
                    noteCtrl.text, onDone),
                child: const Text('Reddet'),
              ),
            ],
          ],
        ),
      ),
    );
    noteCtrl.dispose();
  }

  static Future<void> _approve(
    BuildContext ctx,
    WidgetRef ref,
    String tellerId,
    String action,
    String note,
    VoidCallback onDone,
  ) async {
    try {
      await ref.read(adminRemoteProvider).approveLiveTeller(
            tellerId,
            action: action,
            note: note.trim().isEmpty ? null : note.trim(),
          );
      if (ctx.mounted) Navigator.pop(ctx);
      onDone();
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    }
  }

  static Future<void> showWithdrawalLimitSheet(
    BuildContext context,
    WidgetRef ref, {
    required String userId,
    required VoidCallback onDone,
  }) async {
    final limitCtrl = TextEditingController(text: '1000');
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Çekim limiti',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: limitCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Limit (jeton/CFC)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final limit = int.tryParse(limitCtrl.text.trim());
                if (limit == null || limit < 0) return;
                try {
                  await ref.read(adminRemoteProvider).setWithdrawalLimit(
                        userId: userId,
                        limit: limit,
                      );
                  if (ctx.mounted) Navigator.pop(ctx);
                  onDone();
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(ApiException.userMessage(e))),
                    );
                  }
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
    limitCtrl.dispose();
  }

  static Future<void> showCreateRoomSheet(
    BuildContext context,
    WidgetRef ref, {
    required String userId,
    required VoidCallback onDone,
  }) async {
    final titleCtrl = TextEditingController(text: 'Admin oda');
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Kullanıcı adına sesli oda',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Oda adı',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                try {
                  await ref.read(adminRemoteProvider).createVoiceRoomForUser(
                        userId: userId,
                        title: titleCtrl.text.trim(),
                      );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Oda oluşturuldu')),
                    );
                  }
                  onDone();
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(ApiException.userMessage(e))),
                    );
                  }
                }
              },
              child: const Text('Oda aç'),
            ),
          ],
        ),
      ),
    );
    titleCtrl.dispose();
  }

  static Future<void> togglePkBan(
    BuildContext context,
    WidgetRef ref, {
    required String userId,
    required bool currentlyBanned,
    required VoidCallback onDone,
  }) async {
    final pk = PkRoomRemoteDataSource(ref.read(dioProvider));
    try {
      if (currentlyBanned) {
        await pk.unban(userId);
      } else {
        await pk.banUser(userId: userId, reason: 'admin_action');
      }
      onDone();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(currentlyBanned ? 'PK ban kaldırıldı' : 'PK banlandı'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    }
  }

  static Future<void> reviewPayment(
    BuildContext context,
    WidgetRef ref, {
    required Map<String, dynamic> request,
    required String action,
    required VoidCallback onDone,
  }) async {
    final id = resolvePaymentRequestId(request);
    if (id.isEmpty) return;
    String? note;
    if (action == 'reject') {
      note = await showAdminPaymentRejectSheet(context);
      if (note == null) return;
    }
    try {
      await reviewAdminPaymentRequest(
        ref.read(dioProvider),
        requestId: id,
        action: action,
        requestType: resolvePaymentRequestType(request),
        reviewNote: note,
      );
      onDone();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(action == 'approve' ? 'Ödeme onaylandı' : 'Reddedildi'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    }
  }

  static Future<void> showAnimationAssignSheet(
    BuildContext context,
    WidgetRef ref, {
    required String userId,
    required VoidCallback onDone,
  }) async {
    final animations =
        ref.read(adminSiteAnimationListProvider).valueOrNull ?? [];
    if (animations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Animasyon kataloğu boş')),
      );
      return;
    }

    final slot = await showModalBottomSheet<AdminSiteAnimationSlot>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Slot seçin')),
            for (final s in AdminSiteAnimationSlot.values)
              ListTile(
                title: Text(s.label),
                onTap: () => Navigator.pop(ctx, s),
              ),
          ],
        ),
      ),
    );
    if (slot == null || !context.mounted) return;

    final animId = await showModalBottomSheet<String?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('Kaldır'),
              onTap: () => Navigator.pop(ctx, null),
            ),
            for (final a in animations.where((x) => x.isActive))
              ListTile(
                title: Text(a.name),
                subtitle: Text(a.category.label),
                onTap: () => Navigator.pop(ctx, a.id),
              ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;

    try {
      await ref.read(adminSiteAnimationRemoteProvider).assignAnimation(
            userId: userId,
            slot: slot,
            animationId: animId,
          );
      onDone();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Animasyon atandı')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    }
  }

  static void openFullAnimationPage(BuildContext context, String userId) {
    context.push('/admin/site-animations/user-assign');
  }
}
