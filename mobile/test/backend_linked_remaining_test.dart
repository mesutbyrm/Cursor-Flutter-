import 'package:canlifal_social/features/admin/presentation/widgets/admin_user_finance_ledger_section.dart';
import 'package:canlifal_social/features/cosmetics/data/cosmetics_equip_remote_datasource.dart';
import 'package:canlifal_social/features/cosmetics/domain/cosmetic_effect_kind.dart';
import 'package:canlifal_social/features/cosmetics/domain/cosmetic_slot.dart';
import 'package:canlifal_social/features/live/data/datasources/weekly_broadcaster_competition_remote_datasource.dart';
import 'package:canlifal_social/features/moderation/data/datasources/moderation_remote_datasource.dart';
import 'package:canlifal_social/features/moderation/domain/entities/report_target.dart';
import 'package:flutter_test/flutter_test.dart';

/// JSON örnekleri canlifal backend route handler'larının döndürdüğü biçimdir.
void main() {
  group('Kozmetik (createCosmeticPublicHandlers / profile-frames)', () {
    test('zarflı katalog + seçim', () {
      final r = CosmeticsEquipRemoteDataSource.parseSlotBody(
        CosmeticSlot.microphoneFrame,
        {
          'success': true,
          'data': {
            'items': [
              {'id': 'm1', 'name': 'Altın', 'assetUrl': 'https://x/a.png', 'tier': 'gold'},
            ],
            'selected': 'm1',
          },
        },
      );
      expect(r.selected, 'm1');
      final item = CosmeticsEquipRemoteDataSource.itemFromBackend(
        CosmeticSlot.microphoneFrame,
        r.items.single,
      );
      expect(item.id, 'm1');
      expect(item.effectKind, CosmeticEffectKind.imageOverlay);
      expect(item.assetUrl, 'https://x/a.png');
    });

    test('profil çerçevesi: frames + currentFrameId', () {
      final r = CosmeticsEquipRemoteDataSource.parseSlotBody(
        CosmeticSlot.profileFrame,
        {
          'frames': [
            {'id': 'f1', 'name': 'Neon', 'imageUrl': 'https://x/f.png'},
          ],
          'currentFrameId': 'f1',
        },
      );
      expect(r.items.single['id'], 'f1');
      expect(r.selected, 'f1');
    });

    test('isim efekti anahtarla seçilir ve metin efektine eşlenir', () {
      final item = CosmeticsEquipRemoteDataSource.itemFromBackend(
        CosmeticSlot.nameEffect,
        {'id': 'cuid1', 'key': 'rainbow', 'name': 'Gökkuşağı', 'tier': 'free'},
      );
      expect(item.id, 'rainbow');
      expect(item.effectKind, CosmeticEffectKind.rainbowText);
    });

    test('profil efekti ve rozetin backend ucu yok', () {
      expect(CosmeticsEquipRemoteDataSource.endpointFor(CosmeticSlot.profileEffect), isNull);
      expect(CosmeticsEquipRemoteDataSource.endpointFor(CosmeticSlot.badge), isNull);
      expect(
        CosmeticsEquipRemoteDataSource.endpointFor(CosmeticSlot.chatBubble),
        '/api/chat-bubbles',
      );
    });
  });

  group('Yönetici 360 finans (section=earnings|spending)', () {
    test('kazanç özeti + tür kırılımı', () {
      final rows = parseAdminEarnings({
        'gift_income_jeton': 1200,
        'gift_income_count': 7,
        'teller_total_earnings': 50,
        'agency_earnings': 0,
        'jeton_earned_total': 1500,
        'by_type': [
          {'type': 'gift_received', '_sum': {'amount': 1200}, '_count': 7},
        ],
      });
      expect(rows.first.label, 'Hediye geliri');
      expect(rows.first.amount, 1200);
      expect(rows.first.count, 7);
      expect(rows.last.label, 'gift_received');
    });

    test('harcama negatif tutarı mutlak gösterir', () {
      final rows = parseAdminSpending({
        'gift_spent_jeton': 300,
        'gift_spent_count': 2,
        'jeton_spent_total': 450,
        'by_type': [
          {'type': 'gift_send', '_sum': {'amount': -300}, '_count': 2},
        ],
      });
      expect(rows.last.amount, 300);
    });
  });

  group('Haftalık yayıncı yarışması (CFC Arena)', () {
    test('weekly broadcaster yarışması seçilir', () {
      final c = WeeklyBroadcasterCompetitionRemoteDataSource.pickContest([
        {'id': 'a', 'type': 'agency', 'scope': 'weekly'},
        {'id': 'b', 'type': 'broadcaster', 'scope': 'general', 'isFeatured': true},
        {'id': 'c', 'type': 'broadcaster', 'scope': 'weekly'},
      ]);
      expect(c?['id'], 'c');
      expect(
        WeeklyBroadcasterCompetitionRemoteDataSource.pickContest([
          {'id': 'x', 'type': 'room'},
        ]),
        isNull,
      );
    });

    test('leaderboard katılımcılara dönüşür', () {
      final comp = WeeklyBroadcasterCompetitionRemoteDataSource.fromArenaDetail({
        'contest': {
          'name': 'Haftanın yayıncısı',
          'startsAt': '2026-09-28T00:00:00Z',
          'endsAt': '2026-10-05T00:00:00Z',
        },
        'leaderboard': [
          {
            'userId': 'u1',
            'rank': 1,
            'score': 950,
            'displayName': 'eski',
            'user': {'name': 'Zeynep', 'image': 'https://x/z.png'},
          },
        ],
      });
      expect(comp.title, 'Haftanın yayıncısı');
      expect(comp.participants.single.displayName, 'Zeynep');
      expect(comp.participants.single.score, 950);
      expect(comp.participants.single.avatarUrl, 'https://x/z.png');
    });
  });

  group('Şikayet (POST /api/user/report)', () {
    test('nedenler backend listesine eşlenir', () {
      expect(ModerationRemoteDataSource.backendReason(ReportReason.nudity),
          'inappropriate_content');
      expect(ModerationRemoteDataSource.backendReason(ReportReason.impersonation),
          'fake_account');
      expect(ModerationRemoteDataSource.backendReason(ReportReason.hate), 'harassment');
    });

    test('içerik şikayeti ayrıntıya tür, kimlik ve orijinal neden yazılır', () {
      final d = ModerationRemoteDataSource.buildDetails(
        const ReportTarget(
          type: ReportTargetType.shortVideo,
          targetId: 'v9',
          ownerUserId: 'u1',
        ),
        ReportReason.hate,
        ' kötü ',
      );
      expect(d, 'Nefret söylemi — Kısa video: v9 — kötü');
    });
  });
}
