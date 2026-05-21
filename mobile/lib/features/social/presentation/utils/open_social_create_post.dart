import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Instagram tarzı tam ekran paylaşım oluşturucu.
void openSocialCreatePost(BuildContext context, {String? initialCaption}) {
  context.push('/social/create', extra: initialCaption);
}
