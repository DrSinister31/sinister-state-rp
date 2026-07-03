#!/bin/bash
set -e

cd Kronus

echo "[kronus] Starting all services..."

python kronus_core/main.py &
PID1=$!

python kronus_ai/main.py &
PID2=$!

python kronus_economy/main.py &
PID3=$!

python kronus_enforce/main.py &
PID4=$!

echo "[kronus] All services running (PIDs: $PID1 $PID2 $PID3 $PID4)"

wait -n
