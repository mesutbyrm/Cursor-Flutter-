import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Üretimde kaldırılan veya mobilde yasak legacy yollar (lib/ taraması).
const _forbiddenInLib = <String>{
  '/api/auth/login',
  '/api/auth/register',
  '/api/auth/refresh',
  '/api/auth/me',
  '/api/auth/google',
  '/api/auth/tiktok',
  '/api/banners',
  '/api/devices/fcm',
  '/api/daily-rewards',
  '/api/fortune-access/consume',
  '/api/notifications/unread',
  '/api/social/public-stats',
  '/api/tournaments/join',
  '/api/users/me/gifts-received',
  '/api/users/me/stats',
};

Set<String> _literalsInFile(String path) {
  final source = File(path).readAsStringSync();
  return RegExp(r"""['"](/api/[^'"]+)['"]""")
      .allMatches(source)
      .map((m) => m.group(1)!)
      .toSet();
}

Iterable<File> _dartFilesUnderLib() sync* {
  final dir = Directory('lib');
  if (!dir.existsSync()) return;
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) yield entity;
  }
}

void main() {
  test('lib/ does not embed forbidden legacy API path literals', () {
    final violations = <String>[];
    for (final file in _dartFilesUnderLib()) {
      final relative = file.path.replaceAll('\\', '/');
      if (relative.endsWith('api_path_v1.dart') ||
          relative.endsWith('api_version_interceptor.dart') ||
          relative.endsWith('api_config.dart')) {
        continue;
      }
      for (final literal in _literalsInFile(relative)) {
        if (_forbiddenInLib.contains(literal) ||
            literal.startsWith('/api/pk/battles')) {
          violations.add('$relative → $literal');
        }
      }
    }
    expect(
      violations,
      isEmpty,
      reason: 'Forbidden API paths:\n${violations.join('\n')}',
    );
  });
}
