import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_editor/video_editor.dart';

/// video_editor + FFmpeg ile kırpılmış video dışa aktarır; hız uygulanır.
Future<String> exportEditedShortVideo(
  VideoEditorController controller, {
  double playbackSpeed = 1.0,
}) async {
  final config = VideoFFmpegVideoEditorConfig(controller);
  final execute = await config.getExecuteConfig();

  final session = await FFmpegKit.execute(execute.command);
  final code = await session.getReturnCode();
  if (!ReturnCode.isSuccess(code)) {
    final logs = await session.getOutput();
    throw Exception('Video dışa aktarma başarısız: $logs');
  }

  final file = File(execute.outputPath);
  if (!await file.exists()) {
    throw Exception('Çıktı dosyası bulunamadı');
  }

  final speed = playbackSpeed.clamp(0.5, 2.0);
  if ((speed - 1.0).abs() < 0.01) {
    return execute.outputPath;
  }

  return _applyPlaybackSpeed(execute.outputPath, speed);
}

Future<String> _applyPlaybackSpeed(String inputPath, double speed) async {
  final dir = await getTemporaryDirectory();
  final outPath =
      '${dir.path}/short_speed_${DateTime.now().millisecondsSinceEpoch}.mp4';
  final ptsFactor = (1 / speed).toStringAsFixed(4);
  final audioFilter = _atempoChain(speed);
  final cmd =
      '-y -i "$inputPath" -filter:v "setpts=${ptsFactor}*PTS" -filter:a "$audioFilter" -c:v libx264 -preset ultrafast -c:a aac "$outPath"';
  final session = await FFmpegKit.execute(cmd);
  final code = await session.getReturnCode();
  if (!ReturnCode.isSuccess(code)) {
    final logs = await session.getOutput();
    throw Exception('Hız uygulanamadı: $logs');
  }
  if (!await File(outPath).exists()) {
    return inputPath;
  }
  return outPath;
}

String _atempoChain(double speed) {
  if (speed <= 0.5) return 'atempo=0.5';
  if (speed <= 1.0) return 'atempo=$speed';
  if (speed <= 2.0) return 'atempo=$speed';
  return 'atempo=2.0';
}

int coverTimeMs(VideoEditorController controller) {
  return controller.selectedCoverVal?.timeMs ??
      controller.startTrim.inMilliseconds;
}
