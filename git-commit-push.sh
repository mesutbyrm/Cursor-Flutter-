#!/bin/bash
set -e
cd /workspace
git checkout main
git pull origin main
git add api/src mobile/lib mobile/docs mobile/pubspec.yaml mobile/CHANGELOG.md docs/CANLIFAL_COM_PUSH.md
git status --short > /workspace/git-st.txt
git commit -m "feat: anlık OneSignal push — mesaj, ödeme, canlı yayın

- API push_events + mesaj/admin/ödeme/canlı tetikleyicileri
- Flutter: bildirim tıklama yönlendirme, foreground yenileme
- canlifal.com entegrasyon rehberi; sürüm 1.0.47+49" || true
git push origin main 2>&1 | tail -5 > /workspace/git-push3.txt
