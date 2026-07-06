#!/bin/bash
set -e
cd "$(dirname "$0")"

export PYTHONPATH=Kronus:gta:$PYTHONPATH

echo "[kronus] Starting all services..."

python Kronus/kronus_core/main.py &
PID1=$!
echo "  kronus-core PID=$PID1"

python gta/ai/main.py &
PID2=$!
echo "  gta-ai PID=$PID2"

python gta/economy/main.py &
PID3=$!
echo "  gta-economy PID=$PID3"

python gta/enforce/main.py &
PID4=$!
echo "  gta-enforce PID=$PID4"

python Kronus/kronus_compendium/main.py &
PID5=$!
echo "  kronus-compendium PID=$PID5"

echo "[kronus] All 5 services launched"
wait -n
