#!/bin/bash
set -e
cd "$(dirname "$0")"

export PYTHONPATH=Kronus:$PYTHONPATH

echo "[kronus] Starting all services..."

python Kronus/kronus_core/main.py &
PID1=$!
echo "  kronus-core PID=$PID1"

python Kronus/kronus_ai/main.py &
PID2=$!
echo "  kronus-ai PID=$PID2"

python Kronus/kronus_economy/main.py &
PID3=$!
echo "  kronus-economy PID=$PID3"

python Kronus/kronus_enforce/main.py &
PID4=$!
echo "  kronus-enforce PID=$PID4"

echo "[kronus] All 4 services launched"
wait -n
