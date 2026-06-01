#!/bin/bash
cd /workspace
git status -sb > /workspace/git-status2.txt
git log -2 --oneline >> /workspace/git-status2.txt
