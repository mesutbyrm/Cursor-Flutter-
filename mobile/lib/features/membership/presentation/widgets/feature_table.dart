import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../domain/membership_model.dart';

class MembershipFeatureTable extends StatelessWidget {
  const MembershipFeatureTable({
    super.key,
    required this.selectedTier,
  });

  final MembershipTierId selectedTier;

  static const _headers = ['Basic', 'Gold', 'Premium', 'Diamond'];

  int get _selectedCol => selectedTier.index;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;
        final labelW = compact ? 108.0 : 140.0;
        final colW = ((constraints.maxWidth - labelW - 24) / 4)
            .clamp(compact ? 52.0 : 64.0, 96.0);

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: MembershipCatalogData.glassBorder),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.03),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: MembershipCatalogData.purple.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: labelW + colW * 4 + 24,
                  child: Column(
                    children: [
                      _HeaderRow(
                        labelWidth: labelW,
                        colWidth: colW,
                        selectedCol: _selectedCol,
                      ),
                      ...MembershipCatalogData.featureRows
                          .asMap()
                          .entries
                          .map(
                            (e) => _FeatureDataRow(
                              row: e.value,
                              labelWidth: labelW,
                              colWidth: colW,
                              selectedCol: _selectedCol,
                              zebra: e.key.isOdd,
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 180.ms, duration: 400.ms)
            .slideY(begin: 0.06, end: 0, duration: 420.ms);
      },
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.labelWidth,
    required this.colWidth,
    required this.selectedCol,
  });

  final double labelWidth;
  final double colWidth;
  final int selectedCol;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              'Özellik',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
          for (var i = 0; i < MembershipFeatureTable._headers.length; i++)
            SizedBox(
              width: colWidth,
              child: Text(
                MembershipFeatureTable._headers[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: i == selectedCol
                      ? MembershipCatalogData.gold
                      : Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeatureDataRow extends StatelessWidget {
  const _FeatureDataRow({
    required this.row,
    required this.labelWidth,
    required this.colWidth,
    required this.selectedCol,
    required this.zebra,
  });

  final MembershipFeatureRow row;
  final double labelWidth;
  final double colWidth;
  final int selectedCol;
  final bool zebra;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      color: zebra ? Colors.white.withValues(alpha: 0.03) : null,
      child: Row(
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              row.label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
                height: 1.2,
              ),
            ),
          ),
          for (var i = 0; i < row.values.length; i++)
            SizedBox(
              width: colWidth,
              child: Center(
                child: _Cell(
                  value: row.values[i],
                  highlighted: i == selectedCol,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.value, required this.highlighted});

  final MembershipFeatureValue value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return switch (value) {
      MembershipFeatureText(:final text) => Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: highlighted
                ? MembershipCatalogData.gold
                : Colors.white.withValues(alpha: 0.88),
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      MembershipFeatureBool(:final enabled) => Icon(
          enabled ? Icons.check_circle_rounded : Icons.remove_rounded,
          size: 18,
          color: enabled
              ? (highlighted
                  ? MembershipCatalogData.gold
                  : const Color(0xFF34D399))
              : Colors.white.withValues(alpha: 0.28),
        ),
    };
  }
}
