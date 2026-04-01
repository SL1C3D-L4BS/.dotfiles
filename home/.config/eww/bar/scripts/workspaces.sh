#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
# workspaces.sh — i3 workspace monitor for eww
# Outputs JSON array of workspace objects on every change
# ══════════════════════════════════════════════════════════════
set -euo pipefail

# Find i3 socket — eww doesn't inherit I3SOCK
export I3SOCK=$(find /run/user/1000/i3 -name "ipc-socket.*" 2>/dev/null | head -1)
[[ -z "$I3SOCK" ]] && { echo "[]"; exit 1; }

PERSISTENT="1,2,3,4,5,6,7,8,9,10"

get_workspaces() {
  i3-msg -t get_workspaces 2>/dev/null | python3 -c "
import json, sys

# ── Workspace icons ──────────────────────────────────────────
# 1: Dev (terminal)  2: Code (editors)  3: Browser  4: Database  5: Chat
# 6: Media    7: Files     8: Settings  9: Gaming   10: Misc
ICONS = {
    1: '\ue795',       #  terminal/dev
    2: '\ue795',       #  terminal/code
    3: '\U000f059f',   # 󰖟 web (browser)
    4: '\U000f01bc',   # 󰆼 database
    5: '\U000f0b79',   # 󰭹 chat
    6: '\U000f075a',   # 󰝚 music
    7: '\U000f024b',   # 󰉋 folder
    8: '\U000f0493',   # 󰒓 settings
    9: '\U000f02a0',   # 󰊠 gamepad
    10: '\U000f068c',  # 󰚌 hexagon
}
persistent = set(range(1, 11))

ws_list = json.load(sys.stdin)
active_nums = {w['num'] for w in ws_list}
all_nums = sorted(active_nums | persistent)

result = []
for num in all_nums:
    ws = next((w for w in ws_list if w['num'] == num), None)
    result.append({
        'num': num,
        'name': ICONS.get(num, str(num)),
        'focused': ws['focused'] if ws else False,
        'visible': ws['visible'] if ws else False,
        'urgent': ws['urgent'] if ws else False,
        'empty': ws is None
    })

print(json.dumps(result, ensure_ascii=False))
"
}

# Initial output
get_workspaces

# Subscribe to workspace events and re-emit on changes
i3-msg -t subscribe -m '["workspace"]' 2>/dev/null | while read -r _; do
  get_workspaces
done
