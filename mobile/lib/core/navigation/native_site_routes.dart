import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Site yolu → native Flutter route (WebView yok).
void openNativeSitePath(BuildContext context, String path) {
  final p = path.trim();
  if (p.isEmpty) return;

  if (p.startsWith('/auth/forgot-password') ||
      p.startsWith('/auth/reset-password') ||
      p.startsWith('/sifre-sifirla')) {
    context.push('/auth/forgot-password');
    return;
  }
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
  if (p.startsWith('/canli-falcilar')) {
    context.push(p.startsWith('/') ? p : '/$p');
    return;
  }
  if (p == '/populer-falcilar') {
    context.push('/canli-falcilar');
    return;
  }
  if (p == '/falci-ol') {
    context.push('/content-hub');
    return;
  }
  if (p == '/ajans-ol') {
    context.push('/content-hub');
    return;
  }
  if (p == '/fan-club' || p.contains('fan-club')) {
    context.push('/content-hub');
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
  if (p == '/profile/growth' ||
      p.contains('gorev') ||
      p.contains('görev') ||
      p.contains('reward') ||
      p.contains('odul') ||
      p.contains('ödül')) {
    context.push('/profile/growth');
    return;
  }
  if (p == '/profile' || p.contains('profil')) {
    context.go('/profile');
    return;
  }
  context.push('/content-hub');
}
