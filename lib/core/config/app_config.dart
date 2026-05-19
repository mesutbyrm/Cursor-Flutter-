class AppConfig {
  const AppConfig({
    this.apiBaseUrl = 'https://canlifal.com/api',
    this.webSocketUrl = 'wss://canlifal.com/ws',
    this.liveKitUrl = '',
  });

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      apiBaseUrl: String.fromEnvironment(
        'CANLIFAL_API_URL',
        defaultValue: 'https://canlifal.com/api',
      ),
      webSocketUrl: String.fromEnvironment(
        'CANLIFAL_WS_URL',
        defaultValue: 'wss://canlifal.com/ws',
      ),
      liveKitUrl: String.fromEnvironment('CANLIFAL_LIVEKIT_URL'),
    );
  }

  final String apiBaseUrl;
  final String webSocketUrl;
  final String liveKitUrl;

  /// JWT REST API (`/api/v1/...`) yanıt sarmalayıcısı kullanır.
  bool get usesV1Envelope => apiBaseUrl.contains('/api/v1');
}
