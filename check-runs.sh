#!/bin/bash
gh run list --workflow=build-apk.yml --repo mesutbyrm/Cursor-Flutter- --limit 8 > /workspace/runs2.txt 2>&1
