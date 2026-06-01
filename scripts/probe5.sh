#!/bin/sh
R=cmop292m2005vnv08mx81j1hn
curl -sS "https://canlifal.com/api/chat/rooms/$R" -o /workspace/scripts/room.json
curl -sS -X POST -H "Content-Type: application/json" -d '{"videoId":"dQw4w9WgXcQ","title":"test"}' "https://canlifal.com/api/chat/rooms/$R/song-request" -o /workspace/scripts/sr_post.json -w "%{http_code}" > /workspace/scripts/sr_code.txt
curl -sS -X POST -H "Content-Type: application/json" -d '{"action":"add","userId":"cmokscu2y0000pnko11nctqw5"}' "https://canlifal.com/api/chat/rooms/$R/dj" -o /workspace/scripts/dj_post.json -w "%{http_code}" > /workspace/scripts/dj_code.txt
