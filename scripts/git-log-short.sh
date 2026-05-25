#!/bin/bash
cd /workspace
git log -1 --oneline > /workspace/git-log-1.txt 2>&1
git status -sb | head -5 >> /workspace/git-log-1.txt 2>&1
