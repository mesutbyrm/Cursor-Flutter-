import '../../voice_hub/domain/entities/voice_gift_revenue.dart';

/// Hediye jeton gösterimi — kamuya gross, alıcı/yayıncıya net.
abstract final class GiftRevenueDisplay {
  /// Canlı yayın: yayıncı payı %50.
  static int liveBroadcasterNet(int gross) {
    if (gross <= 0) return 0;
    return (gross * 0.5).round();
  }

  /// Herkesin gördüğü hediye tutarı (brüt).
  static int publicGross(int gross) => gross < 0 ? 0 : gross;

  /// Sesli oda — API yanıtı yoksa:
  /// - Yayıncıya: %50 alıcı, %50 site
  /// - Misafire: %35 alıcı, %15 yayıncı, %50 site
  static VoiceGiftRevenueBreakdown estimateVoiceGift({
    required int gross,
    required bool receiverIsOwner,
  }) {
    if (gross <= 0) {
      return const VoiceGiftRevenueBreakdown(
        total: 0,
        roomType: 'NORMAL',
        receiverNet: 0,
        ownerNet: 0,
        siteAmount: 0,
      );
    }
    if (receiverIsOwner) {
      final receiverNet = (gross * 0.5).round();
      final site = gross - receiverNet;
      return VoiceGiftRevenueBreakdown(
        total: gross,
        roomType: 'NORMAL',
        receiverNet: receiverNet,
        ownerNet: receiverNet,
        siteAmount: site,
      );
    }
    final receiverNet = (gross * 0.35).round();
    final ownerNet = (gross * 0.15).round();
    final site = gross - receiverNet - ownerNet;
    return VoiceGiftRevenueBreakdown(
      total: gross,
      roomType: 'NORMAL',
      receiverNet: receiverNet,
      ownerNet: ownerNet,
      siteAmount: site < 0 ? 0 : site,
    );
  }

  /// Yayıncı/oda sahibinin gördüğü net jeton.
  static int voiceOwnerDisplayNet({
    required int gross,
    required bool receiverIsOwner,
    VoiceGiftRevenueBreakdown? revenue,
  }) {
    final r = revenue != null && revenue.total > 0
        ? revenue
        : estimateVoiceGift(gross: gross, receiverIsOwner: receiverIsOwner);
    if (receiverIsOwner) return r.receiverNet;
    return r.ownerNet;
  }

  /// Hediye alan kişinin gördüğü tutar (brüt — 100 jeton).
  static int voiceReceiverDisplayGross(int gross) => publicGross(gross);

  /// Alıcının gerçek net kazancı (yalnızca alıcıya özel toast).
  static int voiceReceiverNet({
    required int gross,
    required bool receiverIsOwner,
    VoiceGiftRevenueBreakdown? revenue,
  }) {
    final r = revenue != null && revenue.total > 0
        ? revenue
        : estimateVoiceGift(gross: gross, receiverIsOwner: receiverIsOwner);
    return r.receiverNet;
  }
}
