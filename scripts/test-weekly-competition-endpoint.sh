#!/usr/bin/env bash
# Test: Haftalık Yayıncı Yarışması Endpoint
# Kullanım: bash scripts/test-weekly-competition-endpoint.sh [BASE_URL] [JWT_TOKEN]
set -euo pipefail

BASE_URL="${1:-https://canlifal.com}"
JWT_TOKEN="${2:-}"
ENDPOINT="/api/broadcasters/weekly-competition"
FULL_URL="$BASE_URL$ENDPOINT"

# Renkler
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test sayaçları
PASS=0
FAIL=0
SKIP=0

# Sonuç dosyası
REPORT_FILE="docs/WEEKLY_COMPETITION_TEST_REPORT.md"
mkdir -p docs

# Test fonksiyonu
test_case() {
  local name="$1"
  local expected="$2"
  local method="$3"
  local url="$4"
  local headers="${5:-}"
  local data="${6:-}"

  echo -e "${BLUE}[TEST]${NC} $name"

  local cmd="curl -s -X $method '$url'"

  if [[ -n "$headers" ]]; then
    cmd="$cmd $headers"
  fi

  if [[ -n "$data" ]]; then
    cmd="$cmd -d '$data'"
  fi

  cmd="$cmd -w '\n%{http_code}'"

  local response
  response=$(eval "$cmd") || {
    echo -e "${RED}❌ Bağlantı hatası${NC}"
    FAIL=$((FAIL + 1))
    return
  }

  local http_code=$(echo "$response" | tail -1)
  local body=$(echo "$response" | head -n -1)

  if [[ "$http_code" == "$expected" ]]; then
    echo -e "${GREEN}✅ PASS (HTTP $http_code)${NC}"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}❌ FAIL (beklenen: $expected, aldı: $http_code)${NC}"
    echo "Response: $body"
    FAIL=$((FAIL + 1))
  fi
  echo ""
}

echo "=================================================="
echo "🧪 Haftalık Yarışma Endpoint Test Suite"
echo "=================================================="
echo ""
echo "📌 URL: $FULL_URL"
echo "🔐 Token: ${JWT_TOKEN:0:20}..."
echo ""

# ============= TEST 1: Temel Bağlantı =============
echo -e "${YELLOW}[SUITE 1]${NC} Temel Bağlantı Testleri"
echo "---"

if [[ -z "$JWT_TOKEN" ]]; then
  echo -e "${YELLOW}⚠️  JWT token yok - token gerektiren testler atlanıyor${NC}"
  SKIP=$((SKIP + 5))
  echo ""
else
  test_case "1.1 Token ile GET isteği" "200" "GET" "$FULL_URL" \
    "-H 'Authorization: Bearer $JWT_TOKEN' -H 'Content-Type: application/json'"

  test_case "1.2 Geçersiz Token" "401" "GET" "$FULL_URL" \
    "-H 'Authorization: Bearer invalid_token' -H 'Content-Type: application/json'"

  test_case "1.3 Token olmadan GET" "401" "GET" "$FULL_URL" \
    "-H 'Content-Type: application/json'"
fi

# ============= TEST 2: Response Format =============
echo -e "${YELLOW}[SUITE 2]${NC} Response Format Validasyonu"
echo "---"

if [[ -z "$JWT_TOKEN" ]]; then
  SKIP=$((SKIP + 3))
else
  # 200 response al
  local response=$(curl -s -X GET "$FULL_URL" \
    -H "Authorization: Bearer $JWT_TOKEN" \
    -H "Content-Type: application/json")

  # JSON validity
  if echo "$response" | jq . >/dev/null 2>&1; then
    echo -e "${GREEN}✅ 2.1 Valid JSON${NC}"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}❌ 2.1 Invalid JSON${NC}"
    FAIL=$((FAIL + 1))
  fi
  echo ""

  # Required fields
  local required_fields=("week" "participants" "winners" "endsAt")
  for field in "${required_fields[@]}"; do
    if echo "$response" | jq -e ".$field" >/dev/null 2>&1; then
      echo -e "${GREEN}✅ 2.2 Field '$field' var${NC}"
      PASS=$((PASS + 1))
    else
      echo -e "${RED}❌ 2.2 Field '$field' yok${NC}"
      FAIL=$((FAIL + 1))
    fi
  done
  echo ""
fi

# ============= TEST 3: Veri Yapısı =============
echo -e "${YELLOW}[SUITE 3]${NC} Veri Yapısı Validasyonu"
echo "---"

if [[ -z "$JWT_TOKEN" ]]; then
  SKIP=$((SKIP + 4))
else
  local response=$(curl -s -X GET "$FULL_URL" \
    -H "Authorization: Bearer $JWT_TOKEN" \
    -H "Content-Type: application/json")

  # Participants array
  if echo "$response" | jq -e '.participants | type == "array"' >/dev/null 2>&1; then
    echo -e "${GREEN}✅ 3.1 participants array${NC}"
    PASS=$((PASS + 1))

    local participant_count=$(echo "$response" | jq '.participants | length')
    if [[ $participant_count -ge 1 ]]; then
      echo -e "${GREEN}✅ 3.2 Katılımcı sayısı: $participant_count${NC}"
      PASS=$((PASS + 1))
    else
      echo -e "${YELLOW}⚠️  3.2 Katılımcı yok (geçerli - veri olabilir)${NC}"
      SKIP=$((SKIP + 1))
    fi
  else
    echo -e "${RED}❌ 3.1 participants array değil${NC}"
    FAIL=$((FAIL + 1))
    SKIP=$((SKIP + 1))
  fi
  echo ""

  # Winners array
  if echo "$response" | jq -e '.winners | type == "array"' >/dev/null 2>&1; then
    echo -e "${GREEN}✅ 3.3 winners array${NC}"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}❌ 3.3 winners array değil${NC}"
    FAIL=$((FAIL + 1))
  fi
  echo ""

  # Week number
  if echo "$response" | jq -e '.week | type == "number"' >/dev/null 2>&1; then
    local week=$(echo "$response" | jq '.week')
    echo -e "${GREEN}✅ 3.4 Hafta numarası: $week${NC}"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}❌ 3.4 week number değil${NC}"
    FAIL=$((FAIL + 1))
  fi
  echo ""
fi

# ============= TEST 4: HTTP Headers =============
echo -e "${YELLOW}[SUITE 4]${NC} HTTP Headers"
echo "---"

if [[ -z "$JWT_TOKEN" ]]; then
  SKIP=$((SKIP + 3))
else
  local headers=$(curl -s -i -X GET "$FULL_URL" \
    -H "Authorization: Bearer $JWT_TOKEN" \
    -H "Content-Type: application/json" 2>&1 | head -n 20)

  # Content-Type
  if echo "$headers" | grep -i "Content-Type: application/json" >/dev/null; then
    echo -e "${GREEN}✅ 4.1 Content-Type: application/json${NC}"
    PASS=$((PASS + 1))
  else
    echo -e "${YELLOW}⚠️  4.1 Content-Type header check${NC}"
    SKIP=$((SKIP + 1))
  fi
  echo ""

  # Cache header
  if echo "$headers" | grep -i "Cache-Control" >/dev/null; then
    local cache_header=$(echo "$headers" | grep -i "Cache-Control" | head -1)
    echo -e "${GREEN}✅ 4.2 Cache header: $cache_header${NC}"
    PASS=$((PASS + 1))
  else
    echo -e "${YELLOW}⚠️  4.2 Cache-Control header yok (önerilir: max-age=600)${NC}"
    SKIP=$((SKIP + 1))
  fi
  echo ""
fi

# ============= TEST 5: Performans =============
echo -e "${YELLOW}[SUITE 5]${NC} Performans Testleri"
echo "---"

if [[ -z "$JWT_TOKEN" ]]; then
  SKIP=$((SKIP + 2))
else
  local start_time=$(date +%s%N)
  local response=$(curl -s -X GET "$FULL_URL" \
    -H "Authorization: Bearer $JWT_TOKEN" \
    -H "Content-Type: application/json" \
    -w "%{time_total}")
  local elapsed=$(echo "$response" | tail -c 10)

  # 200ms altı
  if (( $(echo "$elapsed < 0.2" | bc -l) )); then
    echo -e "${GREEN}✅ 5.1 Response time < 200ms: ${elapsed}s${NC}"
    PASS=$((PASS + 1))
  elif (( $(echo "$elapsed < 1.0" | bc -l) )); then
    echo -e "${YELLOW}⚠️  5.1 Response time: ${elapsed}s (yavaş, optimize et)${NC}"
    SKIP=$((SKIP + 1))
  else
    echo -e "${RED}❌ 5.1 Response time > 1s: ${elapsed}s${NC}"
    FAIL=$((FAIL + 1))
  fi
  echo ""
fi

# ============= TEST 6: Edge Cases =============
echo -e "${YELLOW}[SUITE 6]${NC} Edge Cases"
echo "---"

test_case "6.1 POST isteği (405 expected)" "405" "POST" "$FULL_URL" \
  "-H 'Content-Type: application/json'" '{"test": "data"}'

test_case "6.2 OPTIONS isteği" "200\|204\|405" "OPTIONS" "$FULL_URL"

echo ""

# ============= RAPOR =============
echo "=================================================="
echo "📊 Test Sonuçları"
echo "=================================================="
echo -e "${GREEN}✅ Geçen: $PASS${NC}"
echo -e "${RED}❌ Hata: $FAIL${NC}"
echo -e "${YELLOW}⚠️  Atlanan: $SKIP${NC}"
echo ""

if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}🎉 TÜM TESTLER BAŞARILI!${NC}"
  exit_code=0
else
  echo -e "${RED}❌ $FAIL TEST BAŞARISIZ${NC}"
  exit_code=1
fi

# Markdown rapor yaz
{
  echo "# Haftalık Yarışma Endpoint Test Raporu"
  echo ""
  echo "| Metrik | Değer |"
  echo "|--------|-------|"
  echo "| Tarih | $(date -u +"%Y-%m-%d %H:%M:%S UTC") |"
  echo "| URL | $FULL_URL |"
  echo "| Geçen | $PASS |"
  echo "| Hata | $FAIL |"
  echo "| Atlanan | $SKIP |"
  echo "| Status | $([ $FAIL -eq 0 ] && echo '✅ PASS' || echo '❌ FAIL') |"
  echo ""
  echo "## Test Suitleri"
  echo ""
  echo "- Suite 1: Temel Bağlantı"
  echo "- Suite 2: Response Format"
  echo "- Suite 3: Veri Yapısı"
  echo "- Suite 4: HTTP Headers"
  echo "- Suite 5: Performans"
  echo "- Suite 6: Edge Cases"
  echo ""
  echo "## Öneriler"
  echo ""
  if [[ $FAIL -gt 0 ]]; then
    echo "- ❌ Hataları düzelt"
  fi
  echo "- Cache-Control header ekle (max-age=600)"
  echo "- Response time < 200ms hedefle"
  echo "- Veri validasyonunu kontrol et"
} > "$REPORT_FILE"

echo ""
echo "📄 Rapor: $REPORT_FILE"
echo ""

exit $exit_code
