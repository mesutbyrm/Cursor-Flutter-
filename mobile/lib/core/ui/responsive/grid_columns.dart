import 'package:flutter/widgets.dart';

/// Ekran genişliğine göre ızgara sütun sayısı — telefonda [min], tablette
/// daha fazla sütun (kutular aşırı büyümesin).
int responsiveGridColumns(
  BuildContext context, {
  required int min,
  double tileWidth = 96,
  int max = 8,
}) {
  final w = MediaQuery.sizeOf(context).width;
  final n = (w / tileWidth).floor();
  if (n < min) return min;
  if (n > max) return max;
  return n;
}
