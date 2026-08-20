import 'package:flutter/material.dart';

import '../../theme/home_approved_design.dart';

/// Yatay kart listesi — tutarlı padding, sağdan kesilme yok.
class HomeHorizontalList extends StatelessWidget {
  const HomeHorizontalList({
    super.key,
    required this.height,
    required this.itemCount,
    required this.itemBuilder,
    this.separatorWidth = 10,
    this.padding,
  });

  final double height;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double separatorWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding ??
            const EdgeInsets.only(
              left: HomeApprovedDesign.hPad,
              right: HomeApprovedDesign.hPad + 4,
            ),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        itemCount: itemCount,
        separatorBuilder: (_, _) => SizedBox(width: separatorWidth),
        itemBuilder: itemBuilder,
      ),
    );
  }
}
