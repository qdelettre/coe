#!/usr/bin/env bash
set -euo pipefail

input=$(cat)

transcript_path=$(printf '%s' "$input" | jq -r '.transcript_path // empty')
session_id=$(printf '%s' "$input" | jq -r '.session_id // empty')
session_id=${session_id//[^A-Za-z0-9_-]/_}

[ -n "$transcript_path" ] || exit 0
[ -f "$transcript_path" ] || exit 0

marker_dir="${TMPDIR:-/tmp}/coe-nudge"
mkdir -p "$marker_dir"
marker="$marker_dir/${session_id:-unknown}.done"
[ -f "$marker" ] && exit 0

threshold_tools=15
threshold_edits=5

# Counts rely on Claude Code persisting transcript lines as compact JSON (no space after ':'). If that format changes, counting fails safe (no nudge rather than a false one).
tool_calls=$( { grep -o '"type":"tool_use"' "$transcript_path" || true; } | wc -l | tr -d ' ')
edits=$( { grep -oE '"name":"(Edit|Write|NotebookEdit)"' "$transcript_path" || true; } | wc -l | tr -d ' ')

if [ "$tool_calls" -ge "$threshold_tools" ] || [ "$edits" -ge "$threshold_edits" ]; then
  : > "$marker"
  jq -n \
    --arg ctx "Medium-to-big session detected (${edits} edits, ${tool_calls} tool calls). Offer the user the option to run /coe for a Correction-of-Errors retrospective. Do NOT run it automatically — only suggest it." \
    '{hookSpecificOutput: {hookEventName: "Stop", additionalContext: $ctx}}'
fi

exit 0
