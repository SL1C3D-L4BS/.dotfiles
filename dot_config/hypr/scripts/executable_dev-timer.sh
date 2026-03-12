#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# SL1C3D-L4BS Dev Timer — brand-styled floating countdown scratchpad
# • First press: Fuzzel picker → starts timer, writes end-time to state file
# • Subsequent presses: toggles the floating window showing remaining time
# • Background alarm daemon: fires notify-send + tone when timer expires
# • Controls: q=cancel  r=restart  any key to refresh
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

STATE="${XDG_RUNTIME_DIR:-/tmp}/sl1c3d-dev-timer"
ALARM_PID="${XDG_RUNTIME_DIR:-/tmp}/sl1c3d-dev-timer-alarm.pid"

# ─── Brand palette (ANSI truecolor) ──────────────────────────────────────────
P='\033[38;2;179;102;255m'   # logo purple
B='\033[38;2;88;101;242m'    # blurple accent
F='\033[38;2;248;248;242m'   # fg
M='\033[38;2;144;144;144m'   # muted
R='\033[38;2;255;85;85m'     # error/warning red
Y='\033[38;2;241;250;140m'   # yellow warning
G='\033[38;2;80;250;123m'    # green ok
BD='\033[1m'                 # bold
RS='\033[0m'                 # reset
CL='\033[2J\033[H'           # clear screen

# ─── Helpers ─────────────────────────────────────────────────────────────────
hms() {
    local s=$1; [[ $s -lt 0 ]] && s=0
    printf '%02d:%02d:%02d' $((s/3600)) $(( (s%3600)/60 )) $((s%60))
}

human() {
    local s=$1
    local h=$((s/3600)) m=$(( (s%3600)/60 ))
    [[ $h -gt 0 ]] && echo "${h}h ${m}m" || echo "${m}m"
}

bar() {
    local pct=$1 width=38 filled empty
    filled=$(( pct * width / 100 ))
    [[ $filled -gt $width ]] && filled=$width
    empty=$(( width - filled ))
    local b=""
    for ((i=0; i<filled; i++)); do b+="█"; done
    for ((i=0; i<empty;  i++)); do b+="░"; done
    echo "$b"
}

# Generate a two-tone alarm beep via Python → paplay (no sound files needed)
play_alarm() {
    python3 - <<'PYEOF' 2>/dev/null | paplay --raw --rate=44100 --format=s16le --channels=1 2>/dev/null &
import math, struct, sys
rate = 44100
def tone(freq, dur, vol=26000):
    n = int(rate * dur)
    return [int(vol * math.sin(2 * math.pi * freq * i / rate)) for i in range(n)]
def fade(samples, fade_in=0.01, fade_out=0.05):
    n = len(samples)
    fi = int(rate * fade_in); fo = int(rate * fade_out)
    for i in range(min(fi, n)):   samples[i] = int(samples[i] * i / fi)
    for i in range(min(fo, n)):   samples[n-1-i] = int(samples[n-1-i] * i / fo)
    return samples
seq = []
for freq, dur in [(880,0.18),(0,0.06),(1100,0.18),(0,0.06),(1320,0.35),(0,0.12),(1100,0.25)]:
    if freq == 0: seq += [0] * int(rate * dur)
    else: seq += fade(tone(freq, dur))
sys.stdout.buffer.write(struct.pack('<' + 'h' * len(seq), *seq))
PYEOF
    true
}

# Fire the alarm: notification + sound + Hyprland native notify
fire_alarm() {
    local label="$1"
    notify-send \
        --urgency=critical \
        --app-name="Dev Timer" \
        --icon=alarm-symbolic \
        "⏰ Timer Complete!" \
        "${label} — time to take a break." \
        2>/dev/null || true
    hyprctl notify 0 8000 "rgb(5865F2)" "⏰ Dev Timer: ${label} complete!" 2>/dev/null || true
    play_alarm
    rm -f "$STATE" "$ALARM_PID"
}

# Background daemon: sleeps in increments until end_time, then fires alarm
start_alarm_daemon() {
    local end_time="$1" label="$2"
    (
        while true; do
            remaining=$(( end_time - $(date +%s) ))
            [[ $remaining -le 0 ]] && { fire_alarm "$label"; break; }
            # Sleep in smaller chunks so kills work cleanly
            sleep_secs=$(( remaining < 30 ? 5 : (remaining < 300 ? 15 : 30) ))
            sleep "$sleep_secs"
        done
    ) &
    echo $! > "$ALARM_PID"
    disown
}

# ─── Countdown display ────────────────────────────────────────────────────────
show_countdown() {
    local end_time="$1" label="$2" total="$3"
    local start_time=$(( end_time - total ))

    tput civis 2>/dev/null || true
    # Restore cursor + echo on exit/interrupt
    trap 'tput cnorm 2>/dev/null; stty echo 2>/dev/null; echo ""' EXIT INT TERM
    stty -echo 2>/dev/null || true

    local last_remaining=-1

    while true; do
        local now remaining elapsed pct time_color
        now=$(date +%s)
        remaining=$(( end_time - now ))
        [[ $remaining -lt 0 ]] && remaining=0
        elapsed=$(( now - start_time ))
        pct=$(( total > 0 ? elapsed * 100 / total : 100 ))
        [[ $pct -gt 100 ]] && pct=100

        # Only redraw if second changed (reduces flicker)
        if [[ $remaining -ne $last_remaining ]]; then
            last_remaining=$remaining

            # Pick time color based on urgency
            if   [[ $remaining -eq 0 ]];       then time_color="$R"
            elif [[ $remaining -le 300 ]];     then time_color="$R"  # < 5 min
            elif [[ $remaining -le 600 ]];     then time_color="$Y"  # < 10 min
            else                                    time_color="$B"
            fi

            local bar_str
            bar_str=$(bar "$pct")

            # ── render ──────────────────────────────────────────────────────
            printf "${CL}"
            printf "\n"
            printf "  ${P}${BD}SL1C3D-L4BS${RS}  ${M}▸${RS}  ${F}${BD}DEV TIMER${RS}\n"
            printf "  ${M}─────────────────────────────────────────${RS}\n"
            printf "\n"
            printf "  ${M}Session${RS}   ${F}${label}${RS}\n"
            printf "  ${M}Started${RS}   ${F}$(date -d @${start_time} '+%I:%M %p')${RS}\n"
            printf "  ${M}Ends at${RS}   ${F}$(date -d @${end_time}   '+%I:%M %p')${RS}\n"
            printf "\n"
            printf "  ${M}╭──────────────────────────╮${RS}\n"
            printf "  ${M}│${RS}   ${time_color}${BD}  $(hms $remaining)  ${RS}   ${M}│${RS}\n"
            printf "  ${M}╰──────────────────────────╯${RS}\n"
            printf "\n"
            printf "  ${B}${bar_str}${RS}  ${M}${pct}%%${RS}\n"
            printf "\n"
            printf "  ${M}Remaining: ${F}$(human $remaining)${RS}\n"
            printf "\n"

            if [[ $remaining -eq 0 ]]; then
                printf "  ${R}${BD}⏰  TIME'S UP! — $(human $total) session complete.${RS}\n"
                printf "\n"
                printf "  ${M}Window closes in 5 seconds...${RS}\n"
                tput cnorm 2>/dev/null; stty echo 2>/dev/null
                sleep 5
                break
            fi

            printf "  ${M}──────────────────────────────────────────${RS}\n"
            printf "  ${M}[q] cancel   [r] restart   [?] durations${RS}\n"
        fi

        # Non-blocking keyread (0.8s timeout)
        local key=""
        if read -t 0.8 -rsn1 key 2>/dev/null; then
            case "$key" in
                q|Q)
                    [[ -f "$ALARM_PID" ]] && kill "$(cat "$ALARM_PID")" 2>/dev/null || true
                    rm -f "$STATE" "$ALARM_PID"
                    tput cnorm 2>/dev/null; stty echo 2>/dev/null
                    printf "\n  ${M}Timer cancelled.${RS}\n\n"
                    sleep 1
                    exit 0
                    ;;
                r|R)
                    [[ -f "$ALARM_PID" ]] && kill "$(cat "$ALARM_PID")" 2>/dev/null || true
                    rm -f "$STATE" "$ALARM_PID"
                    tput cnorm 2>/dev/null; stty echo 2>/dev/null
                    exec "$0"
                    ;;
            esac
        fi
    done
}

# ─── Duration picker via Fuzzel ───────────────────────────────────────────────
pick_duration() {
    printf '  25 min   Pomodoro\n  45 min   Focus\n   1 hour  Flow\n   2 hours  Deep Work\n   3 hours  Project\n   4 hours  Marathon' \
        | fuzzel \
            --dmenu \
            --lines=6 \
            --width=34 \
            --prompt="⏱  Duration  " \
            --anchor=center \
        2>/dev/null
}

duration_to_secs() {
    case "$1" in
        *25*)  echo "1500"; return ;;
        *45*)  echo "2700"; return ;;
        *1\ h*|*1h*)  echo "3600"; return ;;
        *2\ h*|*2h*)  echo "7200"; return ;;
        *3\ h*|*3h*)  echo "10800"; return ;;
        *4\ h*|*4h*)  echo "14400"; return ;;
        *)     echo "7200"; return ;;
    esac
}

duration_to_label() {
    case "$1" in
        *25*)  echo "Pomodoro (25m)" ;;
        *45*)  echo "Focus (45m)" ;;
        *1\ h*|*1h*)  echo "Flow (1h)" ;;
        *2\ h*|*2h*)  echo "Deep Work (2h)" ;;
        *3\ h*|*3h*)  echo "Project (3h)" ;;
        *4\ h*|*4h*)  echo "Marathon (4h)" ;;
        *)     echo "Deep Work (2h)" ;;
    esac
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
    # Resume active timer if state file exists
    if [[ -f "$STATE" ]]; then
        read -r end_time label total < "$STATE"
        remaining=$(( end_time - $(date +%s) ))
        if [[ $remaining -gt 0 ]]; then
            show_countdown "$end_time" "$label" "$total"
            return
        else
            # Expired without alarm firing (reboot, etc.) — clean up
            rm -f "$STATE" "$ALARM_PID"
        fi
    fi

    # Pick duration
    local choice
    choice=$(pick_duration) || true
    [[ -z "$choice" ]] && exit 0

    local secs label end_time
    secs=$(duration_to_secs "$choice")
    label=$(duration_to_label "$choice")
    end_time=$(( $(date +%s) + secs ))

    # Persist state so any future toggle picks it up
    printf '%d %s %d\n' "$end_time" "$label" "$secs" > "$STATE"

    # Arm background alarm (survives terminal close)
    start_alarm_daemon "$end_time" "$label"

    # Show live countdown in this terminal
    show_countdown "$end_time" "$label" "$secs"
}

main "$@"
