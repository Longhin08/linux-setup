#!/bin/bash
input=$(cat)

# Repassa o payload pro Orca (fica aqui, e não no settings.json, porque o Orca
# sobrescreve qualquer statusLine cujo comando mencione o script dele)
if [ -x "$HOME/.orca/agent-hooks/claude-statusline.sh" ]; then
  printf "%s" "$input" | /bin/sh "$HOME/.orca/agent-hooks/claude-statusline.sh" >/dev/null 2>&1
fi

MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
ADDED=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
REMOVED=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
USED_TOKENS=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
WINDOW=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
RL5=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
RL7=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

CYAN='\033[36m'; GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'
WHITE='\033[97m'; DIM='\033[90m'; RESET='\033[0m'

SEP=" ${DIM}|${RESET} "

# Pick bar color based on context usage: white < 70, yellow 70-89, red >= 90
if [ "$PCT" -ge 90 ]; then BAR_COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then BAR_COLOR="$YELLOW"
else BAR_COLOR="$WHITE"; fi

FILLED=$((PCT / 10)); EMPTY=$((10 - FILLED))
BAR_FILLED=$(printf "%${FILLED}s" | tr ' ' '=')
BAR_EMPTY=$(printf "%${EMPTY}s" | tr ' ' '-')
BAR="${DIM}[${BAR_COLOR}${BAR_FILLED}${DIM}${BAR_EMPTY}]${RESET}"

MINS=$((DURATION_MS / 60000)); SECS=$(((DURATION_MS % 60000) / 1000))

# Format a token count: "1M" >= 1e6, "84k" >= 1000, raw otherwise
fmt_k() {
  if [ "$1" -ge 1000000 ]; then
    LC_NUMERIC=C awk -v n="$1" 'BEGIN{printf (n%1000000==0)?"%dM":"%.1fM", n/1000000}'
  elif [ "$1" -ge 1000 ]; then echo "$(( $1 / 1000 ))k"; else echo "$1"; fi
}

# Absolute tokens: used / window size (real fields from the payload)
TOK_STR=""
if [ "$USED_TOKENS" -gt 0 ] && [ "$WINDOW" -gt 0 ]; then
  TOK_STR=" ${DIM}($(fmt_k "$USED_TOKENS")/$(fmt_k "$WINDOW"))${RESET}"
fi

# Home shortening
DISPLAY_DIR="${DIR/#$HOME/\~}"

# Git: branch + dirty count + ahead/behind
GIT_INFO=""
if git rev-parse --git-dir > /dev/null 2>&1; then
  BR=$(git branch --show-current 2>/dev/null)
  GIT_INFO="🌿 ${BR}"
  DIRTY=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  if [ "$DIRTY" -gt 0 ]; then
    GIT_INFO="${GIT_INFO} ${RED}✗${DIRTY}${RESET}"
  else
    GIT_INFO="${GIT_INFO} ${GREEN}✓${RESET}"
  fi
  AB=$(git rev-list --left-right --count @{upstream}...HEAD 2>/dev/null)
  if [ -n "$AB" ]; then
    BEHIND=$(echo "$AB" | cut -f1); AHEAD=$(echo "$AB" | cut -f2)
    [ "$AHEAD" -gt 0 ] && GIT_INFO="${GIT_INFO} ${GREEN}↑${AHEAD}${RESET}"
    [ "$BEHIND" -gt 0 ] && GIT_INFO="${GIT_INFO} ${YELLOW}↓${BEHIND}${RESET}"
  fi
fi

LINES="${GREEN}+${ADDED}${RESET} ${RED}-${REMOVED}${RESET}"
COST_FMT=$(LC_NUMERIC=C printf '$%.2f' "$COST")

# Color a usage percentage: green < 70, yellow 70-89, red >= 90
pct_color() {
  if [ "$1" -ge 90 ]; then printf '%b' "$RED"
  elif [ "$1" -ge 70 ]; then printf '%b' "$YELLOW"
  else printf '%b' "$GREEN"; fi
}

# Rate limits: 5h + weekly quota usage
RL_STR=""
if [ -n "$RL5" ] || [ -n "$RL7" ]; then
  RL_STR="${SEP}⚡"
  [ -n "$RL5" ] && RL_STR="${RL_STR} $(pct_color "$RL5")5h ${RL5}%${RESET}"
  [ -n "$RL7" ] && RL_STR="${RL_STR} ${DIM}·${RESET} $(pct_color "$RL7")7d ${RL7}%${RESET}"
fi

# Line 1: model | dir | git | lines
L1="${CYAN}[$MODEL]${RESET}${SEP}📁 ${DISPLAY_DIR}"
[ -n "$GIT_INFO" ] && L1="${L1}${SEP}${GIT_INFO}"
L1="${L1}${SEP}${LINES}"
echo -e "$L1"

# Line 2: context bar | cost | time | rate limits
echo -e "${BAR} ${PCT}%${TOK_STR}${SEP}${YELLOW}${COST_FMT}${RESET}${SEP}⏱️ ${MINS}m ${SECS}s${RL_STR}"
