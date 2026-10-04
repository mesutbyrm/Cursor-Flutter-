import 'package:canlifal_social/core/theme/app_theme.dart';
import 'package:canlifal_social/features/agency/domain/entities/agency_entity.dart';
import 'package:canlifal_social/features/agency/presentation/providers/agency_providers.dart';
import 'package:canlifal_social/features/home/presentation/widgets/approved/home_ref_quick_access.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Approved extends ApprovedAgencyNotifier {
  _Approved(this._agency);
  final AgencyEntity? _agency;
  @override
  ApprovedAgencyState build() =>
      ApprovedAgencyState(agency: _agency, checked: true);
}

Widget _app(AgencyEntity? agency) => ProviderScope(
      overrides: [
        approvedAgencyProvider.overrideWith(() => _Approved(agency)),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(body: HomeRefQuickAccess()),
      ),
    );

void main() {
  testWidgets('ajansı olmayan «Ajans Ol» görür; 5 kutu sığar', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(null));
    await tester.pump(const Duration(milliseconds: 600));
    for (final l in ['Keşfet', 'Tanış & Kaynaş', 'Gold Üyelik', 'Ajans Ol', 'Tüm Özellikler']) {
      expect(find.text(l), findsOneWidget, reason: l);
    }
    expect(find.text('Ajansım'), findsNothing);
    // Sesli Oda ve Lamba Cini kutuları kaldırıldı; tek sıra 5 kutu.
    expect(find.text('Sesli Oda'), findsNothing);
    expect(find.text('Lamba Cini'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('onaylı ajansı olan «Ajansım» görür', (tester) async {
    await tester.pumpWidget(
      _app(
        const AgencyEntity(
          id: 'a1',
          name: 'Yıldız',
          applicationStatus: 'approved',
          isActive: true,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Ajansım'), findsOneWidget);
    expect(find.text('Ajans Ol'), findsNothing);
  });
}
