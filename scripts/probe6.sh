#!/bin/sh
R=cmop292m2005vnv08mx81j1hn
for method in GET POST PUT PATCH DELETE; do
  c=$(curl -sS -o /tmp/m.json -w "%{http_code}" -X "$method" -H "Content-Type: application/json" -d '{"seatIndex":3}' "https://canlifal.com/api/chat/rooms/$R/seats" 2>/dev/null)
  echo "$method seats -> $c $(head -c 50 /tmp/m.json)"
done
for p in \
  "/api/chat/rooms/$R/seat" \
  "/api/chat/rooms/$R/assign-seat" \
  "/api/chat/rooms/$R/take-seat" \
  "/api/chat/rooms/$R/join-seat"; do
  c=$(curl -sS -o /tmp/m.json -w "%{http_code}" -X POST -H "Content-Type: application/json" -d '{"seatIndex":3}' "https://canlifal.com$p" 2>/dev/null)
  echo "POST $c $p $(head -c 50 /tmp/m.json)"
done
