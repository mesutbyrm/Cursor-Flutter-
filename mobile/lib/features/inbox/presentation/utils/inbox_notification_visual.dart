import 'package:flutter/material.dart';

/// Bildirim tipine göre ikon ve renk — canlı yayın, sesli oda, kazanç vb.
(IconData, Color) inboxNotificationVisual(String? type, BuildContext context) {
  final t = (type ?? '').toLowerCase();
  if (t.contains('short') || t.contains('shorts') || t.contains('reels')) {
    return (Icons.play_circle_fill_rounded, const Color(0xFFFF4081));
  }
  if (t.contains('like') || t.contains('begeni') || t.contains('beğeni')) {
    return (Icons.favorite_rounded, const Color(0xFFFF3B6B));
  }
  if (t.contains('comment') || t.contains('yorum')) {
    return (Icons.chat_bubble_rounded, const Color(0xFF4F9DFF));
  }
  if (t.contains('follow') || t.contains('takip')) {
    return (Icons.person_add_rounded, const Color(0xFF7B5CFF));
  }
  if (t.contains('gift') || t.contains('hediye')) {
    return (Icons.card_giftcard_rounded, const Color(0xFFFFB020));
  }
  if (t.contains('payment') ||
      t.contains('odeme') ||
      t.contains('ödeme') ||
      t.contains('cfc') ||
      t.contains('jeton') ||
      t.contains('kazanc') ||
      t.contains('kazanç') ||
      t.contains('earning') ||
      t.contains('withdraw') ||
      t.contains('wallet') ||
      t.contains('credit')) {
    return (Icons.account_balance_wallet_rounded, const Color(0xFF22C55E));
  }
  if (t.contains('live') ||
      t.contains('yayin') ||
      t.contains('yayın') ||
      t.contains('stream')) {
    return (Icons.podcasts_rounded, const Color(0xFFFF4D4D));
  }
  if (t.contains('voice') ||
      t.contains('oda') ||
      t.contains('chat_room') ||
      t.contains('sesli')) {
    return (Icons.mic_rounded, const Color(0xFF7B5CFF));
  }
  if (t.contains('fortune') ||
      t.contains('fal') ||
      t.contains('psychic') ||
      t.contains('seans') ||
      t.contains('teller')) {
    return (Icons.auto_awesome_rounded, const Color(0xFFFFD54F));
  }
  if (t.contains('message') || t.contains('mesaj')) {
    return (Icons.mail_rounded, const Color(0xFF4F9DFF));
  }
  if (t.contains('pk') || t.contains('battle')) {
    return (Icons.sports_martial_arts_rounded, const Color(0xFFFF6B35));
  }
  return (Icons.notifications_rounded, const Color(0xFF7B5CFF));
}

/// Sistem bildirimi kategori etiketi.
String inboxSystemCategoryLabel(String? type) {
  final t = (type ?? '').toLowerCase();
  if (t.contains('payment') ||
      t.contains('odeme') ||
      t.contains('ödeme') ||
      t.contains('cfc') ||
      t.contains('jeton') ||
      t.contains('kazanc') ||
      t.contains('kazanç') ||
      t.contains('earning') ||
      t.contains('withdraw') ||
      t.contains('wallet') ||
      t.contains('credit')) {
    return 'Kazanç & ödeme';
  }
  if (t.contains('live') ||
      t.contains('yayin') ||
      t.contains('yayın') ||
      t.contains('stream')) {
    return 'Canlı yayın';
  }
  if (t.contains('voice') ||
      t.contains('oda') ||
      t.contains('chat_room') ||
      t.contains('sesli')) {
    return 'Sesli sohbet';
  }
  if (t.contains('fortune') ||
      t.contains('fal') ||
      t.contains('psychic') ||
      t.contains('seans') ||
      t.contains('teller')) {
    return 'Canlı Falcılar';
  }
  if (t.contains('gift') || t.contains('hediye')) {
    return 'Hediye';
  }
  if (t.contains('pk') || t.contains('battle')) {
    return 'PK savaşı';
  }
  if (t.contains('follow') || t.contains('takip')) {
    return 'Takip';
  }
  if (t.contains('like') || t.contains('begeni') || t.contains('beğeni')) {
    return 'Beğeni';
  }
  if (t.contains('comment') || t.contains('yorum')) {
    return 'Yorum';
  }
  return 'Sistem bildirimi';
}
