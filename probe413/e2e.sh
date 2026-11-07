#!/bin/bash
set -u
BASE=$1
FIX=$2
OUT=$3
mkdir -p "$OUT/shots" "$OUT/json"
./observer "$OUT/observer.log" &
OBS=$!
sleep 4

scenario() {
  local name=$1 bin=$2
  shift 2
  printf '%s\n' "$name" > /tmp/scenario.txt
  sleep 0.6
  echo "=== $name :: $(basename "$bin") $*"
  "$bin" "$@" > "$OUT/json/$name.json" 2>&1
  echo "exit=$?" >> "$OUT/json/$name.json"
  cat "$OUT/json/$name.json"
  sleep 0.6
  ./poster state | tee -a "$OUT/json/$name.json"
  screencapture -x "$OUT/shots/$name.png"
}

scenario 01-base-lcmd+rcmd "$BASE" press lcmd+rcmd
scenario 02-fix-lcmd+rcmd "$FIX" press lcmd+rcmd
scenario 03-fix-lopt+ropt "$FIX" press lopt+ropt
scenario 04-fix-rcmd+a "$FIX" press rcmd+a
scenario 05-fix-lcmd+rcmd+a "$FIX" press lcmd+rcmd+a
scenario 06-fix-lcmd "$FIX" press lcmd
scenario 07-fix-app-lcmd+rcmd "$FIX" press lcmd+rcmd --app observer
scenario 08-fix-app-lopt+ropt "$FIX" press lopt+ropt --app observer
scenario 09-base-cmd+a "$BASE" press cmd+a
scenario 10-fix-cmd+a "$FIX" press cmd+a
scenario 11-base-shift+tab "$BASE" press shift+tab
scenario 12-fix-shift+tab "$FIX" press shift+tab
scenario 13-base-cmd "$BASE" press cmd
scenario 14-fix-cmd "$FIX" press cmd
scenario 15-fix-lcmd+q-blocked "$FIX" press lcmd+q
scenario 16-fix-rcmd+q-blocked "$FIX" press rcmd+q
scenario 17-fix-ralt+cmd+esc-blocked "$FIX" press ralt+cmd+esc
scenario 18-fix-LCMD+RCMD-uppercase "$FIX" press LCMD+RCMD
scenario 19-fix-lalt+ralt-aliases "$FIX" press lalt+ralt
scenario 20-fix-lmeta+rmeta-aliases "$FIX" press lmeta+rmeta
scenario 21-fix-unknown-lctrl "$FIX" press lctrl+rctrl
scenario 22-base-app-a "$BASE" press a --app observer
scenario 23-fix-app-a "$FIX" press a --app observer
scenario 24-fix-app-rcmd+a "$FIX" press rcmd+a --app observer
scenario 25-fix-batch-lopt+ropt "$FIX" batch '[{"command":"press","args":{"combo":"lopt+ropt"}}]'
scenario 26-fix-cmd+lcmd+a "$FIX" press cmd+lcmd+a
scenario 27-fix-headed-app-rcmd+a "$FIX" --headed press rcmd+a --app observer
scenario 28-fix-headed-app-lcmd+rcmd "$FIX" --headed press lcmd+rcmd --app observer
scenario 28b-fix-shift+lcmd "$FIX" press shift+lcmd
scenario 28c-fix-shift+lcmd+rcmd+a "$FIX" press shift+lcmd+rcmd+a
scenario 28d-fix-lcmd+lcmd+lcmd+a-dedupe "$FIX" press lcmd+lcmd+lcmd+a
soak() {
  local name=$1
  local bin=$FIX
  shift
  if [ "$1" = "--prev" ]; then bin=$PREV; shift; fi
  printf '%s\n' "$name" > /tmp/scenario.txt
  sleep 0.6
  for i in $(seq 1 30); do "$bin" "$@" > /dev/null; sleep 0.15; done
  sleep 0.5
  screencapture -x "$OUT/shots/$name.png"
}
soak 29-soak-prev-unspaced-lcmd+rcmd+a --prev press lcmd+rcmd+a
soak 29-soak-lcmd+rcmd+a press lcmd+rcmd+a
soak 30-soak-batch-lopt+ropt batch '[{"command":"press","args":{"combo":"lopt+ropt"}}]'
soak 31-soak-rcmd+a press rcmd+a
soak 32-soak-lcmd+rcmd press lcmd+rcmd
printf '%s\n' "33-latency" > /tmp/scenario.txt
sleep 0.6
python3 - "$BASE" "$FIX" <<'PY' | tee "$OUT/latency.txt"
import subprocess, sys, time, statistics
base, fix = sys.argv[1], sys.argv[2]
cases = [("base", base, ["press", "cmd+a"]), ("fix", fix, ["press", "cmd+a"]),
         ("base", base, ["press", "a", "--app", "observer"]), ("fix", fix, ["press", "a", "--app", "observer"]),
         ("fix", fix, ["press", "lcmd+rcmd"]), ("fix", fix, ["press", "lcmd+rcmd+a"])]
for _ in range(2):
    for label, binary, args in cases:
        subprocess.run([binary, *args], capture_output=True)
for label, binary, args in cases:
    samples = []
    for _ in range(15):
        start = time.perf_counter()
        subprocess.run([binary, *args], capture_output=True)
        samples.append((time.perf_counter() - start) * 1000)
        time.sleep(0.05)
    print(f"LATENCY {label:4} {' '.join(args):28} min {min(samples):6.1f} ms  median {statistics.median(samples):6.1f} ms  max {max(samples):6.1f} ms")
PY
kill $OBS
python3 - "$OUT/observer.log" <<'PY'
import sys, collections
mode=None; counts=collections.defaultdict(collections.Counter)
for line in open(sys.argv[1]):
    if line.startswith("SCENARIO"):
        parts=line.split(); mode=parts[1] if len(parts)>1 else None; continue
    if mode and "soak" in mode and "local " in line:
        kind=line.split()[1]; kc=line.split("keyCode=")[1].split()[0]; fl=line.split("flags=")[1].split()[0]
        counts[mode][f"{kind}:{kc}:{fl}"]+=1
for m,c in counts.items(): print("SOAK", m, dict(c), "(30 presses; every event must appear 30 times)")
PY
