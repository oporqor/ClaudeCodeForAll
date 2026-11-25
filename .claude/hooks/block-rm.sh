#!/usr/bin/env bash
# PreToolUse hook: block `rm` commands run through the Bash tool.
# Reads the hook JSON from stdin; exit code 2 blocks the call and
# sends stderr back to Claude.

cmd=$(jq -r '.tool_input.command // ""')

echo "Blocked by .claude/hooks/block-rm.sh: 'rm' is not allowed. Command was: $cmd" >&2
echo "Ask the user to delete files manually, or to adjust this hook if deletion is really needed." >&2
exit 2
