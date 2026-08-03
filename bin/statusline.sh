#!/bin/bash
set -f

# ── Parse CLI arguments ──────────────────────────────────
BAR_STYLE=""
USAGE_STYLE=""
TIME_STYLE=""
MINIMAL=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --bar-style) BAR_STYLE="$2"; shift 2 ;;
        --usage-style) USAGE_STYLE="$2"; shift 2 ;;
        --time-style) TIME_STYLE="$2"; shift 2 ;;
        --minimal) MINIMAL=1; shift ;;
        *) shift ;;
    esac
done

minimal="${MINIMAL:-${CLAUDE_STATUSLINE_MINIMAL:-}}"

input=$(cat)

if [ -z "$input" ]; then
    printf "Claude"
    exit 0
fi

# ── Colors ──────────────────────────────────────────────
blue='\033[38;2;137;180;250m'
orange='\033[38;2;250;179;135m'
green='\033[38;2;166;227;161m'
cyan='\033[38;2;137;220;235m'
red='\033[38;2;243;139;168m'
yellow='\033[38;2;249;226;175m'
white='\033[38;2;205;214;244m'
magenta='\033[38;2;203;166;247m'
# Catppuccin Mocha palette
teal='\033[38;2;148;226;213m'
sapphire='\033[38;2;116;199;236m'
mauve='\033[38;2;203;166;247m'
pink='\033[38;2;245;194;231m'
cat_green='\033[38;2;166;227;161m'
cat_yellow='\033[38;2;249;226;175m'
cat_peach='\033[38;2;250;179;135m'
cat_red='\033[38;2;243;139;168m'
dim='\033[2m'
reset='\033[0m'

sep=" ${dim}│${reset} "

# ── Helpers ─────────────────────────────────────────────
format_tokens() {
    local num=$1
    if [ "$num" -ge 1000000 ]; then
        awk "BEGIN {printf \"%.1fm\", $num / 1000000}"
    elif [ "$num" -ge 1000 ]; then
        awk "BEGIN {printf \"%.0fk\", $num / 1000}"
    else
        printf "%d" "$num"
    fi
}

color_for_pct() {
    local pct=$1
    local scheme="${2:-warm}"
    if [ "$scheme" = "cool" ]; then
        if [ "$pct" -ge 90 ]; then printf "$cat_red"
        elif [ "$pct" -ge 70 ]; then printf "$cat_peach"
        elif [ "$pct" -ge 50 ]; then printf "$cat_yellow"
        else printf "$blue"
        fi
    elif [ "$scheme" = "amber" ]; then
        if [ "$pct" -ge 90 ]; then printf "$cat_red"
        elif [ "$pct" -ge 70 ]; then printf "$cat_peach"
        elif [ "$pct" -ge 50 ]; then printf "$cat_yellow"
        else printf "$cat_green"
        fi
    else
        if [ "$pct" -ge 90 ]; then printf "$cat_red"
        elif [ "$pct" -ge 70 ]; then printf "$cat_peach"
        elif [ "$pct" -ge 50 ]; then printf "$cat_yellow"
        else printf "$cat_green"
        fi
    fi
}

build_bar() {
    local pct=$1
    local width=$2
    local scheme="${3:-warm}"
    local style="${BAR_STYLE:-${CLAUDE_STATUSLINE_BAR_STYLE:-diamond}}"
    [ "$pct" -lt 0 ] 2>/dev/null && pct=0
    [ "$pct" -gt 100 ] 2>/dev/null && pct=100

    local filled=$(( pct * width / 100 ))
    local empty=$(( width - filled ))
    local bar_color
    bar_color=$(color_for_pct "$pct" "$scheme")

    local filled_char empty_char
    case "$style" in
        block)   filled_char="█"; empty_char="░" ;;
        dot)     filled_char="●"; empty_char="○" ;;
        diamond) filled_char="▰"; empty_char="▱" ;;
        arrow)   filled_char="▸"; empty_char="▹" ;;
        square)  filled_char="■"; empty_char="□" ;;
        shade)   filled_char="▓"; empty_char="░" ;;
        *)       filled_char="▰"; empty_char="▱" ;;
    esac

    local filled_str="" empty_str=""
    for ((i=0; i<filled; i++)); do filled_str+="$filled_char"; done
    for ((i=0; i<empty; i++)); do empty_str+="$empty_char"; done

    local empty_color='\033[38;2;49;50;68m'

    printf "${bar_color}${filled_str}${empty_color}${empty_str}${reset}"
}

iso_to_epoch() {
    local iso_str="$1"

    local epoch
    epoch=$(date -d "${iso_str}" +%s 2>/dev/null)
    if [ -n "$epoch" ]; then
        echo "$epoch"
        return 0
    fi

    local stripped="${iso_str%%.*}"
    stripped="${stripped%%Z}"
    stripped="${stripped%%+*}"
    stripped="${stripped%%-[0-9][0-9]:[0-9][0-9]}"

    if [[ "$iso_str" == *"Z"* ]] || [[ "$iso_str" == *"+00:00"* ]] || [[ "$iso_str" == *"-00:00"* ]]; then
        epoch=$(env TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%S" "$stripped" +%s 2>/dev/null)
    else
        epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$stripped" +%s 2>/dev/null)
    fi

    if [ -n "$epoch" ]; then
        echo "$epoch"
        return 0
    fi

    return 1
}

format_reset_time() {
    local epoch="$1"
    local style="$2"
    [ -z "$epoch" ] || [ "$epoch" = "null" ] && return

    local result=""
    case "$style" in
        time)
            result=$(date -j -r "$epoch" +"%l:%M%p" 2>/dev/null | sed 's/^ //; s/\.//g' | tr '[:upper:]' '[:lower:]')
            [ -z "$result" ] && result=$(date -d "@$epoch" +"%l:%M%P" 2>/dev/null | sed 's/^ //; s/\.//g')
            ;;
        datetime)
            result=$(date -j -r "$epoch" +"%b %-d, %l:%M%p" 2>/dev/null | sed 's/  / /g; s/^ //; s/\.//g' | tr '[:upper:]' '[:lower:]')
            [ -z "$result" ] && result=$(date -d "@$epoch" +"%b %-d, %l:%M%P" 2>/dev/null | sed 's/  / /g; s/^ //; s/\.//g')
            ;;
        *)
            result=$(date -j -r "$epoch" +"%b %-d" 2>/dev/null | tr '[:upper:]' '[:lower:]')
            [ -z "$result" ] && result=$(date -d "@$epoch" +"%b %-d" 2>/dev/null)
            ;;
    esac
    printf "%s" "$result"
}

format_remaining() {
    local epoch="$1"
    [ -z "$epoch" ] || [ "$epoch" = "null" ] && return

    local now_ts
    now_ts=$(date +%s)
    local remaining=$(( epoch - now_ts ))
    [ "$remaining" -lt 0 ] && remaining=0

    local days=$(( remaining / 86400 ))
    local hours=$(( (remaining % 86400) / 3600 ))
    local mins=$(( (remaining % 3600) / 60 ))

    if [ "$days" -gt 0 ]; then
        printf "%dd·%dh left" "$days" "$hours"
    elif [ "$hours" -gt 0 ]; then
        printf "%dh·%dm left" "$hours" "$mins"
    else
        printf "%dm left" "$mins"
    fi
}

# ── Extract JSON data ───────────────────────────────────
model_name=$(echo "$input" | jq -r 'if (.model | type) == "object" then .model.display_name // "Claude" else .model // "Claude" end')

size=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
[ "$size" -eq 0 ] 2>/dev/null && size=200000

input_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
cache_create=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
cache_read=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
current=$(( input_tokens + cache_create + cache_read ))

used_tokens=$(format_tokens $current)
total_tokens=$(format_tokens $size)

if [ "$size" -gt 0 ]; then
    pct_used=$(( current * 100 / size ))
else
    pct_used=0
fi

effort=""
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
transcript_path="${transcript_path//\\//}"
if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
    # Ground truth: Claude Code stamps `effort` on every assistant record
    effort=$(tail -200 "$transcript_path" 2>/dev/null \
        | jq -rn 'inputs | .effort // empty' 2>/dev/null | tail -1)

    # ultracode is "xhigh + orchestration", so the effort field still reports xhigh —
    # it only surfaces in /effort output. grep narrows the file, jq confirms the line
    # really is command output so the same text quoted in a tool result can't spoof it.
    if [ "$effort" = "xhigh" ] || [ -z "$effort" ]; then
        last_set=$(grep -F 'local-command-stdout>Set effort level to ' "$transcript_path" 2>/dev/null \
            | jq -rn 'inputs
                | select((.message.content? | type) == "string")
                | .message.content
                | select(startswith("<local-command-stdout>Set effort level to "))
                | capture("Set effort level to (?<e>[a-z]+)").e' 2>/dev/null | tail -1)
        [ "$last_set" = "ultracode" ] && effort="ultracode"
    fi
fi
if [ -z "$effort" ]; then
    settings_path="$HOME/.claude/settings.json"
    if [ -f "$settings_path" ]; then
        effort=$(jq -r '.effortLevel // "default"' "$settings_path" 2>/dev/null)
    else
        effort="default"
    fi
fi

effort_badge() {
    case "$effort" in
        ultracode) printf "${teal}${effort}${reset}" ;;
        max)       printf "${yellow}${effort}${reset}" ;;
        xhigh)     printf "${pink}${effort}${reset}" ;;
        high)      printf "${magenta}${effort}${reset}" ;;
        medium)    printf "${sapphire}${effort}${reset}" ;;
        low)       printf "${dim}${effort}${reset}" ;;
        *)         printf "${dim}${effort}${reset}" ;;
    esac
}

# ── Minimal mode: model │ context % │ effort, nothing else ──
if [ -n "$minimal" ]; then
    pct_color=$(color_for_pct "$pct_used" "amber")
    printf "%b" "${orange}${model_name}${reset}${sep}✍️ ${pct_color}${pct_used}%${reset}${sep}$(effort_badge)"
    exit 0
fi

# ── LINE 1: Model │ Context % │ Directory (branch) │ Session │ Thinking ──
pct_color=$(color_for_pct "$pct_used" "amber")
cwd=$(echo "$input" | jq -r '.cwd // ""')
[ -z "$cwd" ] || [ "$cwd" = "null" ] && cwd=$(pwd)
cwd="${cwd//\\//}"
dirname=$(basename "$cwd")

git_branch=""
git_dirty=""
if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null)
    if [ -n "$(git -C "$cwd" status --porcelain 2>/dev/null)" ]; then
        git_dirty="*"
    fi
fi

session_duration=""
session_start=$(echo "$input" | jq -r '.session.start_time // empty')
if [ -n "$session_start" ] && [ "$session_start" != "null" ]; then
    start_epoch=$(iso_to_epoch "$session_start")
    if [ -n "$start_epoch" ]; then
        now_epoch=$(date +%s)
        elapsed=$(( now_epoch - start_epoch ))
        if [ "$elapsed" -ge 3600 ]; then
            session_duration="$(( elapsed / 3600 ))h$(( (elapsed % 3600) / 60 ))m"
        elif [ "$elapsed" -ge 60 ]; then
            session_duration="$(( elapsed / 60 ))m"
        else
            session_duration="${elapsed}s"
        fi
    fi
fi

line1="${orange}${model_name}${reset}"
line1+="${sep}"
line1+="✍️ ${pct_color}${pct_used}%${reset}"
line1+="${sep}"
line1+="${cyan}${dirname}${reset}"
if [ -n "$git_branch" ]; then
    line1+=" ${green}(${git_branch}${red}${git_dirty}${green})${reset}"
fi
if [ -n "$session_duration" ]; then
    line1+="${sep}"
    line1+="${dim}⏱ ${reset}${white}${session_duration}${reset}"
fi
line1+="${sep}"
line1+="$(effort_badge)"

# ── Rate limit lines (from stdin, no API call) ──────────
usage_style="${USAGE_STYLE:-${CLAUDE_STATUSLINE_USAGE_STYLE:-default}}"
time_style="${TIME_STYLE:-${CLAUDE_STATUSLINE_TIME_STYLE:-remaining}}"
rate_lines=""

five_hour_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_hour_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_day_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
seven_day_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

if [ -n "$five_hour_pct" ] && [ -n "$seven_day_pct" ]; then
    five_hour_pct=$(printf "%.0f" "$five_hour_pct")
    seven_day_pct=$(printf "%.0f" "$seven_day_pct")
    five_hour_pct_color=$(color_for_pct "$five_hour_pct")
    seven_day_pct_color=$(color_for_pct "$seven_day_pct" "cool")

    if [ "$usage_style" = "compact" ]; then
        bar_width=12

        five_hour_bar=$(build_bar "$five_hour_pct" "$bar_width")
        five_hour_remaining=$(format_remaining "$five_hour_reset")
        rate_lines="${white}Usage${reset} ${five_hour_bar} ${five_hour_pct_color}${five_hour_pct}%${reset}"
        [ -n "$five_hour_remaining" ] && rate_lines+=" ${dim}(${five_hour_remaining})${reset}"

        seven_day_bar=$(build_bar "$seven_day_pct" "$bar_width" "cool")
        seven_day_remaining=$(format_remaining "$seven_day_reset")
        rate_lines+="${sep}${seven_day_bar} ${seven_day_pct_color}${seven_day_pct}%${reset}"
        [ -n "$seven_day_remaining" ] && rate_lines+=" ${dim}(${seven_day_remaining})${reset}"
    else
        bar_width=10

        five_hour_bar=$(build_bar "$five_hour_pct" "$bar_width")
        five_hour_pct_fmt=$(printf "%3d" "$five_hour_pct")
        rate_lines+="${white}current${reset} ${five_hour_bar} ${five_hour_pct_color}${five_hour_pct_fmt}%${reset}"
        if [ "$time_style" = "absolute" ]; then
            five_hour_reset_str=$(format_reset_time "$five_hour_reset" "time")
            rate_lines+=" ${dim}⟳${reset} ${white}${five_hour_reset_str}${reset}"
        else
            five_hour_remaining=$(format_remaining "$five_hour_reset")
            [ -n "$five_hour_remaining" ] && rate_lines+=" ${dim}(${five_hour_remaining})${reset}"
        fi

        seven_day_bar=$(build_bar "$seven_day_pct" "$bar_width" "cool")
        seven_day_pct_fmt=$(printf "%3d" "$seven_day_pct")
        rate_lines+="\n${white}weekly${reset}  ${seven_day_bar} ${seven_day_pct_color}${seven_day_pct_fmt}%${reset}"
        if [ "$time_style" = "absolute" ]; then
            seven_day_reset_str=$(format_reset_time "$seven_day_reset" "datetime")
            rate_lines+=" ${dim}⟳${reset} ${white}${seven_day_reset_str}${reset}"
        else
            seven_day_remaining=$(format_remaining "$seven_day_reset")
            [ -n "$seven_day_remaining" ] && rate_lines+=" ${dim}(${seven_day_remaining})${reset}"
        fi
    fi
fi

# ── Output ──────────────────────────────────────────────
printf "%b" "$line1"
if [ -n "$rate_lines" ]; then
    if [ "$usage_style" = "compact" ]; then
        printf "\n%b" "$rate_lines"
    else
        printf "\n\n%b" "$rate_lines"
    fi
fi

exit 0
