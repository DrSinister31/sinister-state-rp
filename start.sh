#!/bin/bash
set -e
cd "$(dirname "$0")"

export PYTHONPATH=Kronus:$PYTHONPATH

echo "[kronus] Starting DM services..."

python Kronus/kronus_core/main.py &
PID1=$!
echo "  kronus-core PID=$PID1"

python Kronus/kronus_compendium/main.py &
PID2=$!
echo "  kronus-compendium PID=$PID2"

echo "[kronus] All 2 DM services launched"
wait -n
