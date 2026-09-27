#!/usr/bin/env bash
# AdMob / Play — app-ads.txt canlifal.com kökünde yayınlanmalı.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
echo "=== Canlifal AdMob app-ads.txt ==="
echo "Yayıncı: pub-1362974509433002"
echo "Hedef URL: https://canlifal.com/app-ads.txt"
echo "(Play Console / AdMob → Geliştirici web sitesi canlifal.com olmalı)"
echo ""
echo "--- app-ads.txt içeriği ---"
cat "$ROOT/app-ads.txt"
echo ""
echo "--- ads.txt (web kökü, isteğe bağlı) ---"
echo "https://canlifal.com/ads.txt"
cat "$ROOT/ads.txt"
