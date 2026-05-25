#!/bin/bash
set -euo pipefail
cd /workspace
git add mobile/lib/features/auth/presentation/pages/register_page.dart \
  mobile/lib/features/auth/presentation/pages/login_page.dart
git commit -m "fix(mobile): CI — AppColors.bgCard ve yinelenen import"
git push origin main > /workspace/git-push-fix.txt 2>&1
