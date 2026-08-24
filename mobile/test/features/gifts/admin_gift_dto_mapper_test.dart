import 'package:canlifal_social/features/gifts/domain/admin_gift_dto_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toAssetType maps mp4/webm to video', () {
    expect(AdminGiftDtoMapper.toAssetType('mp4'), 'video');
    expect(AdminGiftDtoMapper.toAssetType('webm'), 'video');
    expect(AdminGiftDtoMapper.toAssetType('lottie'), 'lottie');
  });

  test('createBody uses OpenAPI gift_types field names', () {
    final body = AdminGiftDtoMapper.createBody(
      name: 'Roket',
      nameEn: 'Rocket',
      price: 900,
      cloudStoragePath: 'gifts/animations/rocket.mp4',
      assetUrl: 'https://cdn.example.com/rocket.mp4',
      assetType: 'mp4',
      comboEnabled: false,
      isPremium: false,
      isFullscreen: true,
      isActive: true,
      isHidden: false,
      isFeatured: false,
      isPopular: false,
      isNew: false,
      isLucky: false,
    );

    expect(body['assetType'], 'video');
    expect(body['cloudStoragePath'], 'gifts/animations/rocket.mp4');
    expect(body['assetUrl'], 'https://cdn.example.com/rocket.mp4');
    expect(body.containsKey('animationCloudPath'), isFalse);
    expect(body.containsKey('imageCloudPath'), isFalse);
    expect(body['iconImageCloudPath'], isNull);
  });
}
