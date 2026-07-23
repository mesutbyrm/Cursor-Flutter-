/// Admin hediye create/update gövdeleri — OpenAPI + `gift_types` şeması.
abstract final class AdminGiftDtoMapper {
  /// UI animasyon türü → backend `assetType` (`image|video|lottie|svga|gif`).
  static String toAssetType(String raw) {
    return switch (raw.toLowerCase().trim()) {
      'mp4' || 'webm' => 'video',
      'none' => 'image',
      'rive' => 'lottie',
      _ => raw.toLowerCase().trim(),
    };
  }

  static Map<String, dynamic> createBody({
    required String name,
    required String nameEn,
    required int price,
    String? icon,
    String? category,
    String? tier,
    int? sortOrder,
    String? iconImageCloudPath,
    String? iconImageUrl,
    String? thumbnailCloudPath,
    String? thumbnailUrl,
    String? cloudStoragePath,
    String? assetUrl,
    required String assetType,
    String? soundCloudPath,
    String? soundUrl,
    int? animationDurationMs,
    String? effectColor,
    required bool comboEnabled,
    required bool isPremium,
    required bool isFullscreen,
    required bool isActive,
    required bool isHidden,
    required bool isFeatured,
    required bool isPopular,
    required bool isNew,
    required bool isLucky,
  }) {
    final resolvedAssetType = toAssetType(assetType);
    final hasAsset =
        cloudStoragePath != null ||
        (assetUrl != null && assetUrl.trim().isNotEmpty);
    return {
      'name': name,
      'nameEn': nameEn,
      'price': price,
      if (icon != null && icon.isNotEmpty) 'icon': icon,
      if (category != null && category.isNotEmpty) 'category': category,
      if (tier != null && tier.isNotEmpty) 'tier': tier,
      if (sortOrder != null && sortOrder >= 0) 'sortOrder': sortOrder,
      if (iconImageCloudPath != null) 'iconImageCloudPath': iconImageCloudPath,
      if (iconImageUrl != null && iconImageUrl.isNotEmpty)
        'iconImageUrl': iconImageUrl,
      if (thumbnailCloudPath != null) 'thumbnailCloudPath': thumbnailCloudPath,
      if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
        'thumbnailUrl': thumbnailUrl,
      if (hasAsset) ...{
        'assetType': resolvedAssetType,
        if (cloudStoragePath != null) 'cloudStoragePath': cloudStoragePath,
        if (assetUrl != null && assetUrl.isNotEmpty) 'assetUrl': assetUrl,
      },
      if (soundCloudPath != null) 'soundCloudPath': soundCloudPath,
      if (soundUrl != null && soundUrl.isNotEmpty) 'soundUrl': soundUrl,
      if (animationDurationMs != null && animationDurationMs > 0)
        'animationDurationMs': animationDurationMs,
      if (effectColor != null && effectColor.isNotEmpty)
        'effectColor': effectColor,
      'comboEnabled': comboEnabled,
      'isPremium': isPremium,
      'isFullscreen': isFullscreen,
      'isActive': isActive,
      'isHidden': isHidden,
      'isFeatured': isFeatured,
      'isPopular': isPopular,
      'isNew': isNew,
      'isLucky': isLucky,
      'visibleInVoiceRoom': true,
      'visibleInLiveStream': true,
    };
  }

  /// PATCH — OpenAPI alanları + create ile aynı metadata (kısmi güncelleme).
  static Map<String, dynamic> updateBody({
    required String name,
    required String nameEn,
    required int price,
    String? icon,
    String? category,
    String? tier,
    int? sortOrder,
    bool iconChanged = false,
    String? iconImageCloudPath,
    String? iconImageUrl,
    bool thumbnailChanged = false,
    String? thumbnailCloudPath,
    String? thumbnailUrl,
    bool assetChanged = false,
    String? cloudStoragePath,
    String? assetUrl,
    required String assetType,
    required bool hasExistingAsset,
    bool soundChanged = false,
    String? soundCloudPath,
    String? soundUrl,
    int? animationDurationMs,
    String? effectColor,
    required bool comboEnabled,
    required bool isPremium,
    required bool isFullscreen,
    required bool isActive,
    required bool isHidden,
    required bool isFeatured,
    required bool isPopular,
    required bool isNew,
    required bool isLucky,
  }) {
    final body = createBody(
      name: name,
      nameEn: nameEn,
      price: price,
      icon: icon,
      category: category,
      tier: tier,
      sortOrder: sortOrder,
      iconImageCloudPath: iconChanged ? iconImageCloudPath : null,
      iconImageUrl: iconChanged ? iconImageUrl : null,
      thumbnailCloudPath: thumbnailChanged ? thumbnailCloudPath : null,
      thumbnailUrl: thumbnailChanged ? thumbnailUrl : null,
      cloudStoragePath: assetChanged ? cloudStoragePath : null,
      assetUrl: assetChanged ? assetUrl : null,
      assetType: (assetChanged || hasExistingAsset) ? assetType : 'none',
      soundCloudPath: soundChanged ? soundCloudPath : null,
      soundUrl: soundChanged ? soundUrl : null,
      animationDurationMs: animationDurationMs,
      effectColor: effectColor,
      comboEnabled: comboEnabled,
      isPremium: isPremium,
      isFullscreen: isFullscreen,
      isActive: isActive,
      isHidden: isHidden,
      isFeatured: isFeatured,
      isPopular: isPopular,
      isNew: isNew,
      isLucky: isLucky,
    );
    if (!assetChanged && hasExistingAsset) {
      body.remove('cloudStoragePath');
      body.remove('assetUrl');
    }
    if (!iconChanged) {
      body.remove('iconImageCloudPath');
      body.remove('iconImageUrl');
    }
    if (!thumbnailChanged) {
      body.remove('thumbnailCloudPath');
      body.remove('thumbnailUrl');
    }
    if (!soundChanged) {
      body.remove('soundCloudPath');
      body.remove('soundUrl');
    }
    return body;
  }
}
