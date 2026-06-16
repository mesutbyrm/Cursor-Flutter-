/// Premium Fortune — ortam yapılandırması (dart-define).
abstract final class PfConfig {
  static const openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const openAiModel = String.fromEnvironment(
    'OPENAI_MODEL',
    defaultValue: 'gpt-4o-mini',
  );
  static const stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
  );
  static const iyzicoApiKey = String.fromEnvironment('IYZICO_API_KEY');
  static const iyzicoBaseUrl = String.fromEnvironment(
    'IYZICO_BASE_URL',
    defaultValue: 'https://api.iyzipay.com',
  );

  static bool get hasOpenAi => openAiApiKey.isNotEmpty;
  static bool get hasStripe => stripePublishableKey.isNotEmpty;
  static bool get hasIyzico => iyzicoApiKey.isNotEmpty;

  /// Kahve falı kredi maliyeti.
  static const int coffeeReadingCost = 15;

  /// Tarot okuma kredi maliyeti.
  static const int tarotReadingCost = 20;

  /// Rüya tabiri kredi maliyeti.
  static const int dreamReadingCost = 10;

  /// Yeni kullanıcı hoş geldin kredisi.
  static const int welcomeCredits = 50;

  /// Canlı falcı dakika ücreti (kredi).
  static const int liveMinuteCost = 5;
}
