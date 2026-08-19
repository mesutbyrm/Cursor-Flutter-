import 'package:canlifal_social/features/profile/domain/entities/daily_task_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DailyTaskEntity.fromJson — /api/daily-missions', () {
    test('maps type, reward and earnedJeton from production shape', () {
      const json = {
        'type': 'login',
        'title': 'Günlük Giriş',
        'description': 'Uygulamaya giriş yap',
        'reward': 5,
        'icon': '👋',
        'autoComplete': true,
        'completed': true,
        'earnedJeton': 5,
      };

      final task = DailyTaskEntity.fromJson(json);

      expect(task.id, 'login');
      expect(task.title, 'Günlük Giriş');
      expect(task.rewardJeton, 5);
      expect(task.completed, isTrue);
      expect(task.icon, '👋');
    });

    test('completed mission sets progress to target/target', () {
      const json = {
        'type': 'watch_stream',
        'title': 'Canlı Yayın İzle',
        'reward': 5,
        'completed': true,
        'earnedJeton': 5,
      };

      final task = DailyTaskEntity.fromJson(json);

      expect(task.completed, isTrue);
      expect(task.current, 1);
      expect(task.target, 1);
    });

    test('resolvedRoute maps production mission types', () {
      expect(
        const DailyTaskEntity(id: 'open_fortune', title: 'Fal').resolvedRoute,
        '/fortune',
      );
      expect(
        const DailyTaskEntity(id: 'share', title: 'Paylaş').resolvedRoute,
        '/invite-friends',
      );
    });

    test('completed mission is treated as claimed', () {
      const json = {
        'type': 'login',
        'title': 'Günlük Giriş',
        'reward': 5,
        'completed': true,
        'earnedJeton': 5,
      };

      final task = DailyTaskEntity.fromJson(json);

      expect(task.completed, isTrue);
      expect(task.claimed, isTrue);
    });
  });
}
