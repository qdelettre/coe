#!/usr/bin/env bash
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
script="$here/coe-nudge.sh"
fixtures="$here/../skills/coe/evals/files"
fails=0

run() { # $1 = transcript path, $2 = session id ; prints stdout
  printf '{"session_id":"%s","transcript_path":"%s","hook_event_name":"Stop"}' "$2" "$1" | "$script"
}

# Isolate dedup markers per test run
TMPDIR=$(mktemp -d)
export TMPDIR

# Case 1: small session -> no nudge
out=$(run "$fixtures/small-session.jsonl" "sess-small")
if [ -n "$out" ]; then echo "FAIL: small session produced output: $out"; fails=$((fails+1)); else echo "PASS: small session silent"; fi

# Case 2: big session -> nudge JSON with additionalContext
out=$(run "$fixtures/big-session.jsonl" "sess-big")
if printf '%s' "$out" | jq -e '.hookSpecificOutput.additionalContext | test("/coe")' >/dev/null 2>&1; then
  echo "PASS: big session nudges with /coe"
else
  echo "FAIL: big session did not nudge: $out"; fails=$((fails+1))
fi

# Case 3: dedup -> second run for same session is silent
out=$(run "$fixtures/big-session.jsonl" "sess-big")
if [ -z "$out" ]; then echo "PASS: dedup silences second run"; else echo "FAIL: dedup did not silence: $out"; fails=$((fails+1)); fi

# Case 4: missing transcript -> silent, exit 0
out=$(run "/nonexistent/path.jsonl" "sess-missing")
if [ -z "$out" ]; then echo "PASS: missing transcript silent"; else echo "FAIL: missing transcript produced output"; fails=$((fails+1)); fi

# Threshold boundary cases (fixtures built in $TMPDIR, never committed)
nudges() { printf '%s' "$1" | jq -e '.hookSpecificOutput.additionalContext | test("/coe")' >/dev/null 2>&1; }

# Single line packing N tool_use occurrences proves occurrence-counting (not line-counting)
line_with_tools() { # $1 = count
  local i out=""
  for ((i = 0; i < $1; i++)); do out="$out\"type\":\"tool_use\","; done
  printf '{"x":[%s]}\n' "$out"
}

line_with_edits() { # $1 = count of Edit names + a couple of tool_use
  local i out="\"type\":\"tool_use\",\"type\":\"tool_use\","
  for ((i = 0; i < $1; i++)); do out="$out\"name\":\"Edit\","; done
  printf '{"x":[%s]}\n' "$out"
}

# Case 5: exactly 15 tool_use occurrences, 0 edits -> NUDGES (locks >=15)
line_with_tools 15 > "$TMPDIR/tools-15.jsonl"
out=$(run "$TMPDIR/tools-15.jsonl" "sess-tools-15")
if nudges "$out"; then echo "PASS: 15 tool_use occurrences nudge"; else echo "FAIL: 15 tool_use occurrences did not nudge: $out"; fails=$((fails+1)); fi

# Case 6: exactly 14 tool_use occurrences, 0 edits -> SILENT
line_with_tools 14 > "$TMPDIR/tools-14.jsonl"
out=$(run "$TMPDIR/tools-14.jsonl" "sess-tools-14")
if [ -z "$out" ]; then echo "PASS: 14 tool_use occurrences silent"; else echo "FAIL: 14 tool_use occurrences nudged: $out"; fails=$((fails+1)); fi

# Case 7: exactly 5 edits, few tools -> NUDGES (locks >=5)
line_with_edits 5 > "$TMPDIR/edits-5.jsonl"
out=$(run "$TMPDIR/edits-5.jsonl" "sess-edits-5")
if nudges "$out"; then echo "PASS: 5 edits nudge"; else echo "FAIL: 5 edits did not nudge: $out"; fails=$((fails+1)); fi

# Case 8: exactly 4 edits, few tools -> SILENT
line_with_edits 4 > "$TMPDIR/edits-4.jsonl"
out=$(run "$TMPDIR/edits-4.jsonl" "sess-edits-4")
if [ -z "$out" ]; then echo "PASS: 4 edits silent"; else echo "FAIL: 4 edits nudged: $out"; fails=$((fails+1)); fi

rm -rf "$TMPDIR"
[ "$fails" -eq 0 ] || { echo "$fails test(s) failed"; exit 1; }
echo "all nudge tests passed"
