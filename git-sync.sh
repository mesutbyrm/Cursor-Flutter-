#!/bin/bash
set -e
cd /workspace
git stash push -u -m temp -- api/.env docs/LATEST_APK_BUILD.md release-notes.md runs.txt runs2.txt tmp-* apk-dl 2>/dev/null || git stash push -m temp || true
git pull --rebase origin main
git push origin main
git stash pop 2>/dev/null || true
git log -1 --oneline > /workspace/git-sync-result.txt
