import 'package:canlifal_social/features/fortune/domain/entities/fortune_display_entry.dart';
import 'package:canlifal_social/features/fortune/presentation/data/fortune_display_resolver.dart';
import 'package:canlifal_social/features/fortune/presentation/navigation/fortune_card_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('Fortune navigation', () {
    test('resolveRouteSlug maps tarot and coffee', () {
      expect(FortuneDisplayResolver.resolveRouteSlug('tarot'), 'tarot');
      expect(FortuneDisplayResolver.resolveRouteSlug('coffee'), 'kahve-fali');
    });

    testWidgets('openFortuneTypeDestination navigates to /fortune/{slug}',
        (tester) async {
      final routes = <String>[];
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () => openFortuneTypeDestination(
                        context,
                        const FortuneDisplayEntry(
                          slug: 'tarot',
                          title: 'Tarot',
                        ),
                      ),
                      child: const Text('open'),
                    );
                  },
                ),
              ),
              GoRoute(
                path: '/fortune/:slug',
                builder: (_, state) {
                  routes.add(state.uri.toString());
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(routes, contains('/fortune/tarot'));
    });

    testWidgets('openFortuneTypesCatalog navigates to /fortune/types',
        (tester) async {
      String? route;
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () => openFortuneTypesCatalog(context),
                      child: const Text('all'),
                    );
                  },
                ),
              ),
              GoRoute(
                path: '/fortune/types',
                builder: (_, state) {
                  route = state.uri.toString();
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('all'));
      await tester.pumpAndSettle();
      expect(route, '/fortune/types');
    });

    testWidgets('empty slug falls back to types catalog', (tester) async {
      String? route;
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () => openFortuneTypeDestination(
                        context,
                        const FortuneDisplayEntry(slug: '', title: 'X'),
                      ),
                      child: const Text('bad'),
                    );
                  },
                ),
              ),
              GoRoute(
                path: '/fortune/types',
                builder: (_, state) {
                  route = state.uri.toString();
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('bad'));
      await tester.pumpAndSettle();
      expect(route, '/fortune/types');
    });
  });
}
