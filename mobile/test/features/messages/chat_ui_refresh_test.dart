import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/core/l10n/app_localizations_config.dart';
import 'package:canlifal_social/core/theme/app_theme.dart';
import 'package:canlifal_social/features/messages/domain/entities/message_entities.dart';
import 'package:canlifal_social/features/messages/presentation/widgets/chat_composer.dart';
import 'package:canlifal_social/features/messages/presentation/widgets/chat_message_bubble.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

Widget _host(Widget child, {ThemeData? theme}) => ProviderScope(
  child: MaterialApp(
    theme: theme ?? AppTheme.dark(),
    locale: AppLocalizationsConfig.locale,
    supportedLocales: AppLocalizationsConfig.supportedLocales,
    localizationsDelegates: AppLocalizationsConfig.delegates,
    home: Scaffold(body: child),
  ),
);

void main() {
  group('ChatMessageBubble', () {
    testWidgets('✨ ile başlayan sıradan mesajın metni gizlenmez', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const ChatMessageBubble(
            message: MessageEntity(
              id: 'm1',
              text: '✨ Günaydın canım, bugün nasılsın?',
              isMine: false,
            ),
          ),
        ),
      );
      expect(find.text('✨ Günaydın canım, bugün nasılsın?'), findsOneWidget);
      expect(find.text('Sticker'), findsNothing);
    });

    testWidgets('📷 ile başlayan serbest metin de olduğu gibi görünür', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const ChatMessageBubble(
            message: MessageEntity(
              id: 'm1',
              text: '📷 dünkü fotoğrafları yarın atarım',
              isMine: true,
            ),
          ),
        ),
      );
      expect(find.text('📷 dünkü fotoğrafları yarın atarım'), findsOneWidget);
    });

    testWidgets('uygulamanın niyet mesajı kart olarak gösterilir', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const ChatMessageBubble(
            message: MessageEntity(
              id: 'm1',
              text: '🔮 Fal isteği gönderdi.',
              isMine: false,
            ),
          ),
        ),
      );
      expect(find.text('Fal İsteği'), findsOneWidget);
    });
  });

  group('ChatComposer', () {
    testWidgets('«+» ek menüsü ve mikrofon (sesli mesaj) düğmesi gizli', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          Align(
            alignment: Alignment.bottomCenter,
            child: ChatComposer(
              controller: controller,
              onSend: () {},
              sending: false,
            ),
          ),
        ),
      );
      expect(find.bySemanticsLabel('İstek ve davet gönder'), findsNothing);
      expect(find.byIcon(Icons.add_circle_outline_rounded), findsNothing);
      expect(find.byIcon(Icons.mic_rounded), findsNothing);
      expect(find.bySemanticsLabel('Mesaj gönder'), findsOneWidget);
    });

    testWidgets('açık temada emoji simgesi zeminde görünür', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          ChatComposer(controller: controller, onSend: () {}, sending: false),
          theme: AppTheme.light(),
        ),
      );
      final icon = tester.widget<Icon>(find.byIcon(Icons.emoji_emotions_outlined));
      expect(
        _contrast(icon.color!, AppTheme.light().scaffoldBackgroundColor),
        greaterThan(3),
      );
    });
  });
}
