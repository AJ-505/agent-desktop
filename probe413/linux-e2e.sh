#!/bin/bash
set -u
BASE=$1
FIX=$2
OUT=$3
mkdir -p "$OUT"
openbox &
sleep 1
xev -geometry 600x400+0+0 -event keyboard > "$OUT/xev.log" 2>&1 &
XEV=$!
sleep 1.5
WID=$(xdotool search --name "Event Tester" | head -1)
xdotool windowactivate --sync "$WID" windowfocus --sync "$WID" mousemove 100 100
sleep 0.5
run() {
  local name=$1 bin=$2
  shift 2
  local before
  before=$(wc -l < "$OUT/xev.log")
  printf '=== %s :: %s %s\n' "$name" "$(basename "$bin")" "$*"
  "$bin" "$@"
  echo "exit=$?"
  sleep 0.7
  echo "--- X11 key events seen by xev:"
  tail -n +"$((before + 1))" "$OUT/xev.log" | grep -oE "^(KeyPress|KeyRelease)|keysym 0x[0-9a-f]+, [A-Za-z_0-9]+" | paste - - | sed 's/^/    /'
  echo "--- end"
}
run L01-base-lcmd+a "$BASE" press lcmd+a
run L02-fix-lcmd+a "$FIX" press lcmd+a
run L03-fix-ropt+b "$FIX" press ropt+b
run L04-fix-cmd+c "$FIX" press cmd+c
run L05-base-cmd+c "$BASE" press cmd+c
run L06-fix-ropt+f4-blocked "$FIX" press ropt+f4
run L07-fix-lcmd+l-blocked "$FIX" press lcmd+l
run L08-fix-lcmd+rcmd "$FIX" press lcmd+rcmd
sleep 1
kill $XEV
grep -E "KeyPress|KeyRelease|keysym" "$OUT/xev.log" | grep -oE "(KeyPress|KeyRelease)|keysym 0x[0-9a-f]+, [A-Za-z_]+" | paste - - > "$OUT/xev-keys.log"
cat "$OUT/xev-keys.log"
xmodmap -pke | grep -E "Super|Alt" | head
# final
