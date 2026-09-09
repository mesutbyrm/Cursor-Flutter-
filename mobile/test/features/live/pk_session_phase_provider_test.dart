import 'package:canlifal_social/features/live/domain/pk/pk_session_phase.dart';
import 'package:canlifal_social/features/live/presentation/providers/pk_session_phase_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PkSessionPhaseNotifier.syncFromServer', () {
    test('sets active from incoming without guard failure', () {
      final container = ProviderContainer();
      final notifier = container.read(pkSessionPhaseProvider.notifier);
      notifier.transitionTo(PkSessionPhase.incoming);
      notifier.syncFromServer(
        isEnded: false,
        isActive: true,
        isPending: false,
      );
      expect(container.read(pkSessionPhaseProvider), PkSessionPhase.active);
      container.dispose();
    });

    test('bootstrap ranking phase from idle to incoming on pending', () {
      final container = ProviderContainer();
      final notifier = container.read(pkSessionPhaseProvider.notifier);
      notifier.syncFromServer(
        isEnded: false,
        isActive: false,
        isPending: true,
      );
      expect(container.read(pkSessionPhaseProvider), PkSessionPhase.incoming);
      container.dispose();
    });
  });
}
