#!/bin/bash
OUT=$1
mkdir -p "$OUT"
./observer "$OUT/race-observer.log" &
OBS=$!
sleep 4
for mode in rapid-exit rapid-linger spaced-exit spaced-nolast; do
  printf '%s\n' "$mode" > /tmp/scenario.txt
  sleep 0.5
  for i in $(seq 1 30); do ./poster $mode; sleep 0.15; done
  sleep 0.5
done
kill $OBS
python3 - "$OUT/race-observer.log" <<'PY'
import sys, collections
mode=None; counts=collections.defaultdict(collections.Counter)
for line in open(sys.argv[1]):
    if line.startswith("SCENARIO "): mode=line.split()[1]; continue
    if mode and "flagsChanged" in line:
        kc=line.split("keyCode=")[1].split()[0]; fl=line.split("flags=")[1].split()[0]
        counts[mode][f"{kc}:{fl}"]+=1
for m,c in counts.items(): print(m, dict(c), "(30 chords posted; each event should appear 30 times)")
PY
