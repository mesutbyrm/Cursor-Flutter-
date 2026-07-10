/// YouTube IFrame API HTML — WebView Error 153 için Referer / origin zorunlu.
abstract final class YoutubeEmbedHtml {
  static const refererOrigin = 'https://canlifal.com';

  /// İlk yükleme: IFrame API ile oynatıcı oluşturur.
  static String build({
    required String videoId,
    required bool playing,
    int startSec = 0,
  }) {
    final autoplay = playing ? 1 : 0;
    final start = startSec.clamp(0, 86400);
    final origin = refererOrigin;
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
    #player {
      position: fixed; inset: 0;
      width: 100%; height: 100%;
    }
  </style>
</head>
<body>
  <div id="player"></div>
  <script>
    var player = null;
    var apiReady = false;

    var tag = document.createElement('script');
    tag.src = 'https://www.youtube.com/iframe_api';
    document.head.appendChild(tag);

    function post(msg) {
      try {
        if (window.RoomVideoBridge) RoomVideoBridge.postMessage(msg);
      } catch (e) {}
    }

    function onYouTubeIframeAPIReady() {
      apiReady = true;
      player = new YT.Player('player', {
        videoId: '$videoId',
        playerVars: {
          autoplay: $autoplay,
          mute: 1,
          controls: 0,
          playsinline: 1,
          rel: 0,
          modestbranding: 1,
          start: $start,
          origin: '$origin',
          enablejsapi: 1
        },
        events: {
          onReady: function(e) {
            post('ready');
            try { e.target.unMute(); e.target.setVolume(100); } catch (err) {}
            if ($autoplay === 1) e.target.playVideo();
          },
          onStateChange: function(e) {
            if (e.data === YT.PlayerState.ENDED) post('ended');
            else if (e.data === YT.PlayerState.PLAYING) {
              post('playing');
              // Muted-autoplay tuzağı: onReady'deki unMute genelde tutmuyor;
              // oynatma GERÇEKTEN başladığında unmute güvenilir şekilde çalışır.
              try { e.target.unMute(); e.target.setVolume(100); } catch (err) {}
            }
            else if (e.data === YT.PlayerState.PAUSED) post('paused');
          },
          onError: function(e) { post('error:' + e.data); }
        }
      });
    }

    window.roomVideoCmd = function(json) {
      try {
        var cmd = JSON.parse(json);
        if (!player || typeof player.getPlayerState !== 'function') return false;
        if (cmd.action === 'load') {
          player.loadVideoById({
            videoId: cmd.videoId,
            startSeconds: cmd.startSec || 0
          });
          if (!cmd.playing) setTimeout(function() { player.pauseVideo(); }, 120);
        } else if (cmd.action === 'play') {
          player.playVideo();
        } else if (cmd.action === 'pause') {
          player.pauseVideo();
        } else if (cmd.action === 'seek') {
          player.seekTo(cmd.sec || 0, true);
          if (cmd.playing) player.playVideo();
          else player.pauseVideo();
        } else if (cmd.action === 'unmute') {
          player.unMute();
          player.setVolume(cmd.volume != null ? cmd.volume : 100);
        } else if (cmd.action === 'mute') {
          player.mute();
        }
        return true;
      } catch (e) { return false; }
    };
  </script>
</body>
</html>
''';
  }
}
