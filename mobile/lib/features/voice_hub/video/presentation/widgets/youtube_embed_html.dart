/// YouTube iframe HTML — WebView Error 153 için Referer / origin zorunlu.
abstract final class YoutubeEmbedHtml {
  static const refererOrigin = 'https://canlifal.com';

  static String build({
    required String videoId,
    required bool playing,
    int startSec = 0,
  }) {
    final autoplay = playing ? 1 : 0;
    final start = startSec.clamp(0, 86400);
    final origin = Uri.encodeComponent(refererOrigin);
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <meta name="referrer" content="strict-origin-when-cross-origin">
  <style>
    html, body {
      margin: 0; padding: 0; width: 100%; height: 100%;
      background: #000; overflow: hidden;
    }
    iframe {
      position: fixed; inset: 0;
      width: 100%; height: 100%;
      border: 0;
    }
  </style>
</head>
<body>
  <iframe
    src="https://www.youtube.com/embed/$videoId?autoplay=$autoplay&controls=0&playsinline=1&rel=0&modestbranding=1&enablejsapi=1&start=$start&origin=$origin"
    title="Canlifal video müzik"
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
    allowfullscreen
    referrerpolicy="strict-origin-when-cross-origin">
  </iframe>
</body>
</html>
''';
  }
}
