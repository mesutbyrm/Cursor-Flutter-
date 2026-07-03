import 'package:canlifal_social/core/video/safe_video_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

void main() {
  group('safeVideoPlayerSize', () {
    test('returns fallback for zero size', () {
      const value = VideoPlayerValue(
        duration: Duration.zero,
        size: Size.zero,
      );
      expect(safeVideoPlayerSize(value), kDefaultPortraitVideoSize);
    });

    test('returns valid size when dimensions are positive', () {
      const value = VideoPlayerValue(
        duration: Duration(seconds: 10),
        size: Size(720, 1280),
      );
      expect(safeVideoPlayerSize(value), const Size(720, 1280));
    });
  });

  group('safeVideoAspectRatio', () {
    test('returns fallback for invalid dimensions', () {
      const value = VideoPlayerValue(
        duration: Duration.zero,
        size: Size.zero,
      );
      expect(safeVideoAspectRatio(value), closeTo(9 / 16, 0.001));
    });
  });
}
