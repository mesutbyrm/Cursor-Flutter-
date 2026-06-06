#!/bin/sh
R=cmop292m2005vnv08mx81j1hn
curl -sS -w "\nHTTP:%{http_code}\n" -X POST -H "Content-Type: application/json" -d '{"seatIndex":2}' "https://canlifal.com/api/chat/rooms/$R/seats" > /workspace/scripts/seat_out.txt
curl -sS -w "\nHTTP:%{http_code}\n" -X PATCH -H "Content-Type: application/json" -d '{"backgroundImage":"https://example.com/x.jpg"}' "https://canlifal.com/api/chat/rooms/$R" > /workspace/scripts/patch_out.txt
