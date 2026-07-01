import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:video_editor/video_editor.dart';

/// video_editor + FFmpeg ile kırpılmış video dışa aktarır.
Future<String> exportEditedShortVideo(VideoEditorController controller) async {
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
  return execute.outputPath;
}

int coverTimeMs(VideoEditorController controller) {
  return controller.selectedCoverVal?.timeMs ??
      controller.startTrim.inMilliseconds;
}
