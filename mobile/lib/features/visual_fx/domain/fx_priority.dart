/// Efekt önceliği — aynı anda çok fazla animasyonu engeller.
enum FxPriority {
  critical,
  high,
  normal,
  low;

  int get weight => switch (this) {
        FxPriority.critical => 4,
        FxPriority.high => 3,
        FxPriority.normal => 2,
        FxPriority.low => 1,
      };
}
