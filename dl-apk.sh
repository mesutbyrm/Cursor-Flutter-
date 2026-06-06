#!/bin/bash
set -e
rm -rf /workspace/apk-dl
mkdir -p /workspace/apk-dl
cd /workspace/apk-dl
gh run download 26311458272 --repo mesutbyrm/Cursor-Flutter- --name canlifal-social-release-apk
ls -la > /workspace/apk-dl-list.txt
