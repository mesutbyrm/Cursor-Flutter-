/// Ağ performansı — bağımsız API çağrıları paralel (`Future.wait`).
abstract final class NetworkPerf {
  /// Bağımsız istekleri aynı anda çalıştır.
  static Future<List<T>> parallel<T>(Iterable<Future<T>> futures) =>
      Future.wait(futures);

  /// Pull-to-refresh: paralel bekle; tek istek hatası diğerlerini iptal etmez.
  static Future<void> waitSilent(Iterable<Future<dynamic>> futures) async {
    await Future.wait(
      futures.map(
        (future) => future.catchError((Object _) {}),
      ),
    );
  }
}
