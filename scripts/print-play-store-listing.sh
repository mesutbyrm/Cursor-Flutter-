#!/usr/bin/env bash
# Play Console — Store listing metinleri (kopyala-yapıştır taslak).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="?"
if [[ -f "$ROOT/mobile/pubspec.yaml" ]]; then
  VERSION=$(grep -E '^version:' "$ROOT/mobile/pubspec.yaml" | head -1 | sed 's/version:[[:space:]]*//')
fi

cat <<EOF
=== Play Console → Main store listing ===

App name: Canlifal
Version (current): ${VERSION}
Default language: Turkish (tr-TR) + English (en-US) if listed

Short description (max 80 chars, TR):
Canlı fal, sesli odalar ve sosyal etkileşim — gerçek falcılarla görüntülü görüş.

Full description (TR — taslak):
Canlifal ile canlı falcılarla görüntülü veya sesli görüşme yapın, sesli sohbet odalarına katılın, hediye gönderin ve sosyal akışta paylaşım yapın. Jeton cüzdanı, bildirimler ve gerçek zamanlı oda deneyimi tek uygulamada.

• Canlı falcı görüşmeleri (TRTC)
• Sesli odalar, koltuk ve DJ müzik
• Hediye, PK ve canlı yayın
• Fal, tarot ve sosyal içerik

Gizlilik: https://canlifal.com/gizlilik

Full description (EN — draft):
Connect with live fortune tellers via video or voice, join voice chat rooms, send gifts, and explore social feeds. Wallet, notifications, and real-time rooms in one app.

Privacy: https://canlifal.com/gizlilik

Graphics (user action):
  [ ] Phone screenshots (min 2)
  [ ] 7-inch tablet (optional)
  [ ] Feature graphic 1024×500
  [ ] App icon 512×512 (Play Console upload)

EOF
