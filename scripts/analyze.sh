#!/bin/bash
export PATH="/home/ubuntu/flutter32/bin:$PATH"
cd /workspace/mobile
dart analyze lib/features/voice_hub 2>&1 | grep "error •" | head -30 > /workspace/analyze-errors.txt
wc -l /workspace/analyze-errors.txt >> /workspace/analyze-errors.txt
