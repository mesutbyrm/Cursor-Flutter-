#!/usr/bin/env bash
# Kullanıcı devir teslimi — Psychic P0 öncelik (agent işi bitti).
# Kullanım: bash scripts/user-handoff.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APK_URL="https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk"

VERSION="?"
if [[ -f "${ROOT}/mobile/pubspec.yaml" ]]; then
  VERSION=$(grep -E '^version:' "${ROOT}/mobile/pubspec.yaml" | head -1 | sed 's/version:[[:space:]]*//')
fi

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║  Canlifal — kullanıcı devir teslimi (${VERSION})                  ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "Agent tarafı: TAMAM (kod, CI, API otomasyon M5/M7, dokümantasyon)"
echo "Sizin tarafınız: Psychic P0 — 2 telefon (T+5s donma yok)"
echo ""
echo "── Canlı durum ──"
echo "  bash scripts/release-remaining-status.sh"
echo ""
echo "── Jeton ──"
echo "  ✅ P0-j kapandı (~100k jeton) — bash scripts/psychic-p0-prereqs.sh ile doğrula"
echo ""
echo "── Falcı hesabı ──"
echo "  bash scripts/probe-psychic-teller.sh"
echo "  Host (cursor.host.*) falcı listesinde olmayabilir — onaylı falcı kullanın"
echo ""
echo "── APK ──"
echo "  ${APK_URL}"
echo ""
echo "── Önkoşul (APK + giriş + jeton) ──"
echo "  bash scripts/psychic-p0-prereqs.sh"
echo ""
echo "── Psychic P0 checklist (yazdır) ──"
echo "  bash scripts/psychic-p0-checklist.sh"
echo ""
echo "── Tam E2E (P0 PASS sonrası) ──"
echo "  bash scripts/print-live-psychics-e2e-checklist.sh"
echo ""
echo "── Test hesapları (detay: docs/KULLANICI_TEST_KILAVUZU.md) ──"
echo "  Danışan A: cursor.test.1786235468@mailinator.com"
echo "  Host/Falcı: cursor.host.1786235468@mailinator.com"
echo "  Şifre: CursorTest!1786235468"
echo ""
echo "── Sonuç (bize yazın) ──"
echo "  Psychic P0 PASS  → RELEASE READY adayı"
echo "  Psychic P0 FAIL  → adım + logcat / ekran kaydı"
echo ""
echo "── Sonra (P1) ──"
echo "  docs/RELEASE_CHECKLIST.md — sesli oda, hediye, PK, müzik"
echo ""
echo "── Derleme özeti ──"
bash "${ROOT}/scripts/print-build-status.sh" 2>/dev/null | head -25
