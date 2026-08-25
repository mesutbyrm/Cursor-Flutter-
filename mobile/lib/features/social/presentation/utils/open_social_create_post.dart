import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_providers.dart';

/// Instagram tarzı tam ekran paylaşım oluşturucu.
Future<void> openSocialCreatePost(
  BuildContext context,
  WidgetRef ref, {
  String? initialCaption,
  VoidCallback? onPublished,
}) async {
  final authed = ref.read(authControllerProvider).valueOrNull;
  if (authed == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Paylaşım için giriş yapın'),
      ),
    );
    exitGuestToLogin(ref);
    return;
  }
  final created = await context.push<bool>('/social/create', extra: initialCaption);
  if (created == true) {
    onPublished?.call();
  }
}
