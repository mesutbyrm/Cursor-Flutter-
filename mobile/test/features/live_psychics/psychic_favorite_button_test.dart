import 'package:canlifal_social/core/network/api_exception.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/psychic_favorites_provider.dart';
import 'package:canlifal_social/features/live_psychics/presentation/widgets/psychic_favorite_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _UnfavoriteOkController extends PsychicFavoritesController {
  @override
  Future<Set<String>> build() async => {'teller_1'};

  @override
  Future<bool> toggle(String tellerId) async => false;
}

class _ToggleErrorController extends PsychicFavoritesController {
  @override
  Future<Set<String>> build() async => const {};

  @override
  Future<bool> toggle(String tellerId) async {
    throw const ApiException('Favori güncellenemedi');
  }
}

void main() {
  testWidgets('successful unfavorite does not look like an error', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          psychicFavoritesProvider.overrideWith(_UnfavoriteOkController.new),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: PsychicFavoriteButton(tellerId: 'teller_1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(find.text('Favori güncellenemedi'), findsNothing);
  });

  testWidgets('toggle API error shows snackbar', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          psychicFavoritesProvider.overrideWith(_ToggleErrorController.new),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: PsychicFavoriteButton(tellerId: 'teller_1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(find.text('Favori güncellenemedi'), findsOneWidget);
  });
}
