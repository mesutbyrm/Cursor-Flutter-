import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Site yolu → native Flutter route (WebView yok).
void openNativeSitePath(BuildContext context, String path) {
  final p = path.trim();
  if (p.isEmpty) return;

  if (p.startsWith('/fortune') || p.contains('fal')) {
    context.push(p.startsWith('/') ? p : '/$p');
    return;
  }
  if (p == '/live' || p.startsWith('/live')) {
    context.go('/live');
    return;
  }
  if (p.contains('sohbet') || p.contains('voice')) {
    context.push('/voice-rooms');
    return;
  }
  if (p == '/populer-falcilar' || p.contains('falci')) {
    context.go('/home');
    return;
  }
  if (p.startsWith('/blog') || p.startsWith('/ruya')) {
    context.push('/fortune');
    return;
  }
  if (p == '/jeton-store' || p.contains('jeton')) {
    context.push('/jeton-store');
    return;
  }
  if (p == '/profile' || p.contains('profil')) {
    context.go('/profile');
    return;
  }
  context.push('/content-hub');
}
