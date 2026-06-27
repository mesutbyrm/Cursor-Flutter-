/// TikTok tarzı PK süre seçenekleri — davet gönderirken kullanılır.
class PkDurationOption {
  const PkDurationOption({
    required this.seconds,
    required this.label,
    required this.shortLabel,
  });

  final int seconds;
  final String label;
  final String shortLabel;
}

/// 1, 3, 5 ve 10 dakikalık PK süreleri.
const List<PkDurationOption> pkDurationOptions = [
  PkDurationOption(seconds: 60, label: '1 dakika', shortLabel: '1 dk'),
  PkDurationOption(seconds: 180, label: '3 dakika', shortLabel: '3 dk'),
  PkDurationOption(seconds: 300, label: '5 dakika', shortLabel: '5 dk'),
  PkDurationOption(seconds: 600, label: '10 dakika', shortLabel: '10 dk'),
];

/// Varsayılan PK süresi — 3 dakika.
const int pkDefaultDurationSeconds = 180;

PkDurationOption pkDurationBySeconds(int seconds) {
  for (final o in pkDurationOptions) {
    if (o.seconds == seconds) return o;
  }
  return pkDurationOptions[1];
}
