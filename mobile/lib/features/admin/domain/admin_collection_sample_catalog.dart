import '../../cosmetics/domain/cosmetic_catalog_generators.dart';
import '../../cosmetics/domain/cosmetic_item.dart';
import '../../cosmetics/domain/cosmetic_slot.dart';
import '../../voice_hub/domain/voice_room_background_catalog.dart';
import '../../voice_hub/domain/voice_room_theme_catalog.dart';
import 'achievement_badge_sample.dart';

/// Admin «Hediye & Koleksiyon» örnek kataloğu.
abstract final class AdminCollectionSampleCatalog {
  static const backgroundEffectCount = 40;
  static const roomThemeCount = 20;
  static const avatarAccessoryCount = 20;
  static const microphoneFrameCount = 10;
  static const chatBubbleCount = 10;
  static const nameEffectCount = 20;
  static const membershipBadgeCount = 10;
  static const profileFrameCount = 20;
  static const achievementBadgeCount = 20;

  static List<AdminSampleItem> backgroundEffects() {
    const labels = [
      'Parıltı', 'Neon', 'Aurora', 'Galaksi', 'Ateş', 'Buz', 'Gökkuşağı',
      'Altın Toz', 'Yıldız Yağmuru', 'Kozmik', 'Kristal', 'Sis', 'Lav',
      'Elektrik', 'Çiçek', 'Kelebek', 'Kar', 'Güneş', 'Ay', 'Ejder',
    ];
    return List.generate(backgroundEffectCount, (i) {
      final n = i + 1;
      final label = labels[i % labels.length];
      return AdminSampleItem(
        id: 'bg_effect_$n',
        name: '$label Arkaplan $n',
        category: 'Arkaplan efekti',
        previewUrl: VoiceRoomBackgroundCatalog.urlForIndex(n),
        sortOrder: n,
        tags: const ['efektli', 'animated'],
      );
    });
  }

  static List<VoiceRoomTheme> roomThemes() =>
      VoiceRoomThemeCatalog.samples.take(roomThemeCount).toList();

  static List<CosmeticItem> avatarAccessories() =>
      CosmeticCatalogGenerators.avatarAccessories(count: avatarAccessoryCount);

  static List<CosmeticItem> microphoneFrames() =>
      CosmeticCatalogGenerators.microphoneFrames(count: microphoneFrameCount);

  static List<CosmeticItem> chatBubbles() =>
      CosmeticCatalogGenerators.chatBubbles(count: chatBubbleCount);

  static List<CosmeticItem> nameEffects() =>
      CosmeticCatalogGenerators.nameEffects(count: nameEffectCount);

  static List<CosmeticItem> membershipBadges() =>
      CosmeticCatalogGenerators.membershipBadges(count: membershipBadgeCount);

  static List<CosmeticItem> profileFrames() =>
      CosmeticCatalogGenerators.profileFrames(count: profileFrameCount);

  static List<AchievementBadgeSample> achievementBadges() =>
      AchievementBadgeSampleCatalog.samples.take(achievementBadgeCount).toList();

  static int countForTab(AdminCollectionTab tab) => switch (tab) {
        AdminCollectionTab.backgrounds => backgroundEffects().length,
        AdminCollectionTab.roomThemes => roomThemes().length,
        AdminCollectionTab.avatarAccessories => avatarAccessories().length,
        AdminCollectionTab.microphoneFrames => microphoneFrames().length,
        AdminCollectionTab.chatBubbles => chatBubbles().length,
        AdminCollectionTab.nameEffects => nameEffects().length,
        AdminCollectionTab.membershipBadges => membershipBadges().length,
        AdminCollectionTab.profileFrames => profileFrames().length,
        AdminCollectionTab.achievementBadges => achievementBadges().length,
      };
}

enum AdminCollectionTab {
  backgrounds,
  roomThemes,
  avatarAccessories,
  microphoneFrames,
  chatBubbles,
  nameEffects,
  membershipBadges,
  profileFrames,
  achievementBadges,
}

extension AdminCollectionTabX on AdminCollectionTab {
  String get label => switch (this) {
        AdminCollectionTab.backgrounds => 'Arkaplan',
        AdminCollectionTab.roomThemes => 'Oda teması',
        AdminCollectionTab.avatarAccessories => 'Avatar aksesuarı',
        AdminCollectionTab.microphoneFrames => 'Mikrofon çerçevesi',
        AdminCollectionTab.chatBubbles => 'Sohbet balonu',
        AdminCollectionTab.nameEffects => 'İsim efekti',
        AdminCollectionTab.membershipBadges => 'Üyelik rozeti',
        AdminCollectionTab.profileFrames => 'Profil çerçevesi',
        AdminCollectionTab.achievementBadges => 'Rozet yönetimi',
      };
}

class AdminSampleItem {
  const AdminSampleItem({
    required this.id,
    required this.name,
    required this.category,
    this.previewUrl,
    this.sortOrder = 0,
    this.tags = const [],
  });

  final String id;
  final String name;
  final String category;
  final String? previewUrl;
  final int sortOrder;
  final List<String> tags;
}
