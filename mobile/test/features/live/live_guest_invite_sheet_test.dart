import 'package:canlifal_social/features/live/domain/entities/live_stream_viewer.dart';
import 'package:canlifal_social/features/live/presentation/providers/live_stream_viewers_provider.dart';
import 'package:canlifal_social/features/live/presentation/widgets/broadcast_room/live_guest_invite_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('izleyiciler listelenir, Davet Et → Gönderildi', (tester) async {
    final invited = <String>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          liveStreamViewersProvider.overrideWith(
            (ref, id) async => const [
              LiveStreamViewer(id: 'h', displayName: 'Yayıncı', isBroadcaster: true),
              LiveStreamViewer(id: 'u1', displayName: 'Zeynep', username: 'zey'),
              LiveStreamViewer(id: 'u2', displayName: 'Emre'),
            ],
          ),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showLiveGuestInviteSheet(
                    context,
                    ref,
                    streamId: 's1',
                    hostUserId: 'h',
                    onInvite: (id, name) async {
                      invited.add(id);
                      return true;
                    },
                  ),
                  child: const Text('aç'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();

    expect(find.text('Misafir Davet Et'), findsOneWidget);
    expect(find.text('Kullanıcı ara...'), findsOneWidget);
    expect(find.text('Yayıncı'), findsNothing);
    expect(find.text('Davet Et'), findsNWidgets(2));

    await tester.tap(find.text('Davet Et').first);
    await tester.pumpAndSettle();
    expect(invited, ['u1']);
    expect(find.text('Gönderildi'), findsOneWidget);
    expect(find.text('Davet Et'), findsOneWidget);
  });
}
