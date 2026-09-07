#!/usr/bin/env bash
# Play Console — Foreground Service permissions (kopyala-yapıştır özet).
set -euo pipefail

cat <<'EOF'
=== Play Console → App content → Foreground service permissions ===

1. FOREGROUND_SERVICE_CAMERA
   Amaç: Canlı falcı görüntülü görüşme (TRTC)
   Görünür: Evet — görüşme sırasında kamera açık
   TR: Canlifal'da kullanıcılar canlı falcılarla görüntülü görüşme yapabilir.

2. FOREGROUND_SERVICE_MICROPHONE
   Amaç: Sesli sohbet odaları + canlı sesli/görüntülü görüşme
   Görünür: Evet — oda veya görüşme aktifken
   TR: Sesli odalarda ve canlı falcı görüşmelerinde mikrofon kullanılır.

3. FOREGROUND_SERVICE_MEDIA_PLAYBACK
   Amaç: Sesli odalarda DJ / arka plan müzik
   Görünür: Evet — bildirim çubuğu oynatma kontrolü
   TR: Sesli odalarda DJ müziği arka planda çalar; bildirimden kontrol edilir.

4. FOREGROUND_SERVICE_MEDIA_PROJECTION
   Amaç: Video SDK ekran paylaşımı altyapısı (Agora/TRTC)
   Görünür: Yalnızca kullanıcı ekran paylaşımı başlatırsa
   TR: Görüntülü görüşme SDK'ları ekran paylaşımı için izin gerektirir; kullanıcı açmadıkça kullanılmaz.

Detay + video kanıt: docs/PLAY_FOREGROUND_SERVICE_DECLARATION.md
EOF
