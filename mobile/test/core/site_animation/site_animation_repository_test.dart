import 'package:canlifal_social/core/site_animation/data/site_animation_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SiteAnimationRepository exposes active catalog API', () {
    final repo = SiteAnimationRepository(Dio());
    expect(repo.getActiveCatalog, isNotNull);
    expect(repo.syncFromAdminLocal, isNotNull);
  });
}
