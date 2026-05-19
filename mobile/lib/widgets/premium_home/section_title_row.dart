import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../theme/premium_live_theme.dart';

class SectionTitleRow extends StatelessWidget {
  const SectionTitleRow({
    super.key,
    required this.title,
    this.trailingLabel,
    this.onTrailing,
  });

  final String title;
  final String? trailingLabel;
  final VoidCallback? onTrailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 0.5.w),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              gradient: LinearGradient(
                colors: [
                  Colors.redAccent.shade200,
                  PremiumLiveTheme.neonPink,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: PremiumLiveTheme.neonPink.withValues(alpha: 0.45),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          SizedBox(width: 2.5.w),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.5.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.35,
                color: Colors.white,
              ),
            ),
          ),
          if (trailingLabel != null)
            TextButton(
              onPressed: onTrailing,
              child: Text(
                trailingLabel!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: PremiumLiveTheme.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
