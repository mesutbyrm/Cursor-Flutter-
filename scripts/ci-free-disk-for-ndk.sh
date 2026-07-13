#!/usr/bin/env bash
# CI — NDK indirmesi için disk alanı (CodeQL cache'e dokunmaz).
set -euo pipefail
echo "Önce:"; df -h / | tail -1
sudo rm -rf /usr/share/dotnet /opt/ghc /usr/local/share/powershell /usr/share/swift || true
sudo docker image prune -af 2>/dev/null || true
echo "Sonra:"; df -h / | tail -1
