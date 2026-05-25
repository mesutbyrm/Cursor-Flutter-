#!/bin/bash
cd /workspace
git fetch origin main
git rebase origin/main 2>&1 | tail -5 > /workspace/git-rebase.txt
git push origin main 2>&1 | tail -5 >> /workspace/git-rebase.txt
