import 'package:canlifal_social/core/theme/app_theme.dart';
import 'package:canlifal_social/features/agency/domain/entities/agency_entity.dart';
import 'package:canlifal_social/features/agency/presentation/providers/agency_providers.dart';
import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/auth/presentation/providers/auth_providers.dart';
import 'package:canlifal_social/features/home/presentation/widgets/approved/home_ref_quick_access.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_entity.dart';
import 'package:canlifal_social/features/live_psychics/presentation/controllers/psychics_list_controller.dart';
import 'package:canlifal_social/features/profile/domain/entities/profile_stats_entity.dart';
import 'package:canlifal_social/features/profile/presentation/providers/profile_providers.dart';
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

class _Teller extends ApprovedPsychicNotifier {
  _Teller(this._profile);
  final PsychicEntity? _profile;
  @override
  ApprovedPsychicState build() =>
      ApprovedPsychicState(profile: _profile, checked: true);
}

class _Auth extends AuthController {
  _Auth(this._user);
  final UserEntity? _user;
  @override
  Future<UserEntity?> build() async => _user;
}

Widget _app({
  AgencyEntity? agency,
  PsychicEntity? teller,
  UserEntity? user,
  List<BroadcastHistoryItemEntity> broadcasts = const [],
}) =>
    ProviderScope(
      overrides: [
        approvedAgencyProvider.overrideWith(() => _Approved(agency)),
        approvedPsychicProvider.overrideWith(() => _Teller(teller)),
        authControllerProvider.overrideWith(() => _Auth(user)),
        broadcastHistoryProvider.overrideWith((ref) async => broadcasts),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(body: HomeRefQuickAccess()),
      ),
    );

void main() {
  testWidgets('rolsüz kullanıcı: 2 sıra × 5 kutu, «… Ol» etiketleri',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 900));
    for (final l in [
      'Keşfet',
      'Tanış & Kaynaş',
      'Gold Üyelik',
      'Canlı Falcılar',
      'Tüm Özellikler',
      'Falcı Ol',
      'Ajans Ol',
      'Yayıncı Ol',
      'Jeton Al',
      'Hediye Yolla',
    ]) {
      expect(find.text(l), findsOneWidget, reason: l);
    }
    expect(find.text('Ajansım'), findsNothing);
    expect(find.text('Lamba Cini'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('falcı + ajans + yayıncı «panel» etiketlerini görür',
      (tester) async {
    await tester.pumpWidget(
      _app(
        agency: const AgencyEntity(
          id: 'a1',
          name: 'Yıldız',
          applicationStatus: 'approved',
          isActive: true,
        ),
        teller: const PsychicEntity(id: 'p1', name: 'Falcı'),
        user: const UserEntity(id: 'u1', username: 'u1'),
        broadcasts: const [BroadcastHistoryItemEntity(id: 'b1', title: 'Yayın')],
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(find.text('Ajansım'), findsOneWidget);
    expect(find.text('Falcı Panelim'), findsOneWidget);
    expect(find.text('Yayıncı Paneli'), findsOneWidget);
    expect(find.text('Ajans Ol'), findsNothing);
    expect(find.text('Falcı Ol'), findsNothing);
    expect(find.text('Yayıncı Ol'), findsNothing);
  });
}
