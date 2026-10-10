#!/usr/bin/env bash
# JPG (GenerateImage çıktısı) → WebP; premium + legacy klasörlere kopyalar.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ART="${PREMIUM_ART_DIR:-/opt/cursor/artifacts/assets}"
MOBILE="$ROOT/mobile/assets"

to_webp() {
  local jpg="$1" out="$2"
  [[ -f "$jpg" ]] || { echo "skip missing $jpg"; return 0; }
  ffmpeg -y -i "$jpg" -q:v 82 "$out" 2>/dev/null
  echo "ok $out"
}

install_pair() {
  local jpg_base="$1"
  local premium_rel="$2"
  local legacy_rel="$3"
  local jpg="$ART/${jpg_base}.jpg"
  local premium="$MOBILE/images/premium/$premium_rel"
  local legacy="$MOBILE/$legacy_rel"
  mkdir -p "$(dirname "$premium")" "$(dirname "$legacy")"
  to_webp "$jpg" "$premium"
  cp -f "$premium" "$legacy"
}

# Zodiac
for sign in koc boga ikizler yengec aslan basak terazi akrep yay oglak kova balik; do
  install_pair "zodiac_$sign" "zodiac/${sign}.webp" "zodiac/${sign}.webp"
done

# Membership
for tier in basic gold premium diamond svip; do
  install_pair "membership_$tier" "membership/${tier}.webp" "membership/${tier}.webp"
done

# Fortune
declare -A FORT=(
  [fortune_kahve_fali]=kahve-fali.webp
  [fortune_tarot]=tarot.webp
  [fortune_el_fali]=el-fali.webp
  [fortune_numeroloji]=numeroloji.webp
  [fortune_ruya_tabiri]=ruya-tabiri.webp
  [fortune_ask_fali]=ask-fali.webp
  [fortune_dogum_haritasi]=dogum-haritasi.webp
  [fortune_aura_analizi]=aura-analizi.webp
  [fortune_melek_kartlari]=melek-kartlari.webp
  [fortune_katina]=katina.webp
  [fortune_evet_hayir]=evet-hayir.webp
  [fortune_istihare]=istihare.webp
  [fortune_kursundokme]=kursundokme.webp
  [fortune_pendul]=pendul.webp
  [fortune_runik]=runik.webp
  [fortune_gunluk_fal]=gunluk-fal.webp
  [fortune_cin_fali]=cin-fali.webp
  [fortune_iskambil]=iskambil.webp
  [fortune_yildiz_haritasi]=yildiz-haritasi.webp
)
for base in "${!FORT[@]}"; do
  file="${FORT[$base]}"
  install_pair "$base" "fortune/${file}" "fortune/${file}"
done

echo "Done. Home tiles were installed separately under assets/tiles/."
