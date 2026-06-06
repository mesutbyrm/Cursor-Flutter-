#!/bin/bash
set -euo pipefail
cd /workspace
git add mobile/lib/features/auth mobile/lib/core/config/env.dart mobile/pubspec.yaml
git commit -m "fix(auth): canlifal.com NextAuth giriş — e-posta ve Google OAuth"
git push origin main > /workspace/git-push-auth.txt 2>&1
