import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../models/premium_voice_room_sphere.dart';
import '../../theme/premium_live_theme.dart';

class VoiceSpheresSection extends StatelessWidget {
  const VoiceSpheresSection({super.key, required this.rooms});

  final List<PremiumVoiceRoomSphere> rooms;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 2.w),
        physics: const BouncingScrollPhysics(),
        itemCount: rooms.length,
        separatorBuilder: (_, _) => SizedBox(width: 4.w),
        itemBuilder: (context, i) {
          final r = rooms[i];
          return _VoiceSphere(room: r, index: i)
              .animate()
              .fadeIn(delay: (80 * i).ms, duration: 450.ms)
              .scale(
                begin: const Offset(0.88, 0.88),
                curve: Curves.easeOutBack,
                delay: (80 * i).ms,
              );
        },
      ),
    );
  }
}

class _VoiceSphere extends StatelessWidget {
  const _VoiceSphere({required this.room, required this.index});

  final PremiumVoiceRoomSphere room;
  final int index;

  @override
  Widget build(BuildContext context) {
    final d = 26.w.clamp(96.0, 118.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: d,
          height: d,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: d,
                height: d,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      room.glowColors.first.withValues(alpha: 0.95),
                      room.glowColors.last.withValues(alpha: 0.55),
                      PremiumLiveTheme.voidBlack.withValues(alpha: 0.9),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: room.glowColors.first.withValues(alpha: 0.55),
                      blurRadius: 28,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: room.glowColors.last.withValues(alpha: 0.25),
                      blurRadius: 40,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    room.centerIcon,
                    color: Colors.white.withValues(alpha: 0.95),
                    size: 32.sp,
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.lightGreenAccent.shade400,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.greenAccent.withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 0.9.h),
        _AvatarRowWithCount(urls: room.avatarUrls, count: room.participants),
        SizedBox(height: 0.7.h),
        SizedBox(
          width: d + 12,
          child: Text(
            room.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.15,
            ),
          ),
        ),
        SizedBox(height: 0.25.h),
        Text(
          '${room.participants} kişi',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5.sp,
            fontWeight: FontWeight.w600,
            color: PremiumLiveTheme.textMuted,
          ),
        ),
      ],
    );
  }
}

class _AvatarRowWithCount extends StatelessWidget {
  const _AvatarRowWithCount({required this.urls, required this.count});

  final List<String> urls;
  final int count;

  @override
  Widget build(BuildContext context) {
    final take = urls.take(3).toList();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < take.length; i++)
          Transform.translate(
            offset: Offset(i * -7.0, 0),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white54, width: 1.2),
              ),
              child: ClipOval(
                child: Image.network(
                  take[i],
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => ColoredBox(
                    color: PremiumLiveTheme.cosmicPurple,
                    child: const Icon(Icons.person, size: 12, color: Colors.white38),
                  ),
                ),
              ),
            ),
          ),
        SizedBox(width: take.isEmpty ? 0 : 6),
        Text(
          '$count',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.sp,
            fontWeight: FontWeight.w800,
            color: Colors.white.withValues(alpha: 0.92),
          ),
        ),
      ],
    );
  }
}
