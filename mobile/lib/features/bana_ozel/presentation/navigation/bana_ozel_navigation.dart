import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bana Özel katalog — isteğe bağlı `slug` ile derin bağlantı.
void openBanaOzelCatalog(BuildContext context, {String? slug}) {
  final key = slug?.trim();
  if (key != null && key.isNotEmpty) {
    context.push(
      '/fortune/bana-ozel?slug=${Uri.encodeQueryComponent(key)}',
    );
    return;
  }
  context.push('/fortune/bana-ozel');
}
