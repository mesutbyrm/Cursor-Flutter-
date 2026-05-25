#!/bin/bash
CSRF=$(curl -sS https://canlifal.com/api/auth/csrf | sed -n 's/.*"csrfToken":"\([^"]*\)".*/\1/p')
echo "csrf=${CSRF:0:20}..."
CODE=$(curl -sS -o /workspace/curl-cred.json -w "%{http_code}" -X POST \
  "https://canlifal.com/api/auth/callback/credentials" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "csrfToken=${CSRF}&email=test@example.com&password=wrongpass&callbackUrl=https://canlifal.com&json=true")
echo "code=$CODE"
head -c 400 /workspace/curl-cred.json
