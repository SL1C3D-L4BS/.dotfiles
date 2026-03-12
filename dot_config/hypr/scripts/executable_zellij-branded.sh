#!/usr/bin/env bash
# Start Zellij with SL1C3D-L4BS branding: always a new fresh session, no dead ones kept.
# Unique name per terminal (quote + PID) so we never attach to old; dead sessions cleared on start.

QUOTES=(
	"It compiles"
	"Works on my machine"
	"Delete the code and start over"
	"Fifty million Elvis fans can't be wrong"
	"Hold my beer"
	"Ship it"
	"Just one more fix"
	"Nobody will ever need more than 640K"
	"Trust the process"
	"Rubber duck debugging"
	"Have you tried turning it off and on again"
	"Cache invalidation is hard"
	"There are 2 hard problems in CS: naming and off-by-one"
	"Premature optimization is the root of all evil"
	"Read the docs"
	"Worse is better"
	"Move fast and break things"
	"First make it work then make it right"
	"YOLO merge"
	"LGTM"
)

# Clear all dead sessions so we never accumulate; then start one new session (unique name = always fresh)
zellij delete-all-sessions -y 2>/dev/null || true

QUOTE="${QUOTES[$((RANDOM % ${#QUOTES[@]}))]}"
SESSION_NAME="SL1C3D-L4BS — $QUOTE — $$"
exec zellij -s "$SESSION_NAME" "$@"
