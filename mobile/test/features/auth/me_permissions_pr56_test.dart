import 'package:canlifal_social/features/auth/domain/me_permissions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MePermissions groups catalog list (PR #56)', () {
    final p = MePermissions.fromJson({
      'success': true,
      'data': {
        'role': 'moderator',
        'isSuper': false,
        'permissions': [
          'finance.report.view',
          'moderation.report.handle',
        ],
        'groups': ['finance', 'content', 'moderation', 'system'],
      },
    });
    expect(p.can('finance.report.view'), isTrue);
    expect(p.groups['finance'], ['finance.report.view']);
    expect(p.groups['moderation'], ['moderation.report.handle']);
  });
}
