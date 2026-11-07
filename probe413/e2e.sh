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
kill $OBS
