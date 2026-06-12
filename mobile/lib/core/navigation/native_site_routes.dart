import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Site yolu → native Flutter route (WebView yok).
void openNativeSitePath(BuildContext context, String path) {
  final p = path.trim();
  if (p.isEmpty) return;

  if (p.startsWith('/auth/reset-password') || p.startsWith('/sifre-sifirla')) {
    final uri = Uri.tryParse(p.startsWith('http') ? p : 'https://canlifal.com$p');
    final token = uri?.queryParameters['token'];
    context.push(
      token != null && token.isNotEmpty
          ? '/auth/reset-password?token=${Uri.encodeComponent(token)}'
          : '/auth/reset-password',
    );
    return;
  }
  if (p.startsWith('/auth/forgot-password')) {
    context.push('/auth/forgot-password');
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
  if (p.startsWith('/fortune') || p.contains('fal')) {
    context.push(p.startsWith('/') ? p : '/$p');
    return;
  }
  if (p == '/games-hub' ||
      p == '/oyunlar' ||
      p == '/games' ||
      p.startsWith('/oyunlar/') ||
      p.startsWith('/mini-games/') ||
      p.startsWith('/tournaments') ||
      p.startsWith('/turnuvalar')) {
    context.push('/games-hub');
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
  if (p == '/ajans-ol') {
    context.push('/content-hub');
    return;
  }
  if (p == '/fan-club-hub' ||
      p == '/fan-club' ||
      p.contains('fan-club') ||
      p.contains('fanclub')) {
    context.push('/fan-club-hub');
    return;
  }
  if (p == '/celebrities-hub' ||
      p.startsWith('/unluler') ||
      p.startsWith('/celebrities')) {
    context.push('/celebrities-hub');
    return;
  }
  if (p == '/blog-hub' || p.startsWith('/blog')) {
    context.push('/blog-hub');
    return;
  }
  if (p == '/dreams-hub' ||
      p.startsWith('/ruya-sozlugu') ||
      p.startsWith('/ruya-trendleri') ||
      p.startsWith('/ruya-takvimi') ||
      p.startsWith('/ruya-istatistikleri') ||
      p.startsWith('/ruya-yarismasi')) {
    context.push('/dreams-hub');
    return;
  }
  if (p.startsWith('/ruya') || p.contains('ruya-yorumu')) {
    context.push('/fortune/ruya-tabiri');
    return;
  }
  if (p == '/jeton-store' || p.contains('jeton')) {
    context.push('/jeton-store');
    return;
  }
  if (p == '/ad-rewards' || p.contains('reklam')) {
    context.push('/ad-rewards');
    return;
  }
  if (p == '/profile/growth' ||
      p.contains('gorev') ||
      p.contains('görev') ||
      p.contains('reward') ||
      p.contains('watch-ad') ||
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
