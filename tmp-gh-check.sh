#!/bin/bash
set -e
cd /workspace
git pull origin main -q
grep '^version:' mobile/pubspec.yaml
git log origin/main -2 --oneline
gh run list --workflow=build-apk.yml --limit 4
gh release view apk-latest --repo mesutbyrm/Cursor-Flutter- 2>&1 | head -6
