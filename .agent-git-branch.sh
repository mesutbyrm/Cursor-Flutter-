#!/bin/bash
cd /workspace
git branch --show-current > /workspace/git-branch.txt
git log main -1 --oneline >> /workspace/git-branch.txt
git log HEAD -1 --oneline >> /workspace/git-branch.txt
