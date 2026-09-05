#!/usr/bin/env bash

input=$(cat)

# ── PICK A WORKING PYTHON ───────────────────────────────────────────
# On Windows, `python3` can resolve to the Microsoft Store stub, which
# prints an error and produces no output. Probe each candidate by
# actually running it, and use the first that works.
PYBIN=""
for c in python3 python py; do
  if command -v "$c" >/dev/null 2>&1 && "$c" -c '' >/dev/null 2>&1; then
    PYBIN="$c"; break
  fi
done
[ -z "$PYBIN" ] && PYBIN=python3

# ── RESET ───────────────────────────────────────────────────────────
R="\x1b[0m"; W="\x1b[97m"

# ── 48-COLOR PALETTE ────────────────────────────────────────────────
PRI_PAL=(
  "80;160;255"  "55;115;255"  "100;149;237" "135;140;255"
  "70;140;210"  "25;145;255"  "140;200;255" "100;130;255"
  "0;255;255"   "0;230;210"   "0;185;235"   "85;220;255"
  "110;225;245" "0;200;220"   "160;220;255" "0;220;170"
  "0;200;180"   "60;235;165"  "0;195;155"   "50;215;180"
  "80;225;205"  "80;210;120"  "75;220;135"  "55;195;80"
  "0;255;100"   "120;255;80"  "115;195;115" "90;180;90"
  "175;240;60"  "155;235;50"  "185;100;255" "160;78;255"
  "172;108;252" "140;78;255"  "210;128;255" "200;158;255"
  "200;88;255"  "218;98;240"  "255;0;200"   "255;78;182"
  "255;48;222"  "255;98;162"  "255;128;198" "242;78;148"
  "255;108;168" "195;208;225" "178;188;208" "210;218;240"
)
SEC_PAL=(
  "25;55;120"   "15;35;140"   "35;50;130"   "45;48;155"
  "20;48;95"    "8;48;125"    "45;85;145"   "30;40;145"
  "0;80;100"    "0;78;72"     "0;60;105"    "22;88;125"
  "35;95;115"   "0;68;88"     "55;95;145"   "0;70;55"
  "0;68;60"     "15;95;60"    "0;65;52"     "12;82;68"
  "20;88;78"    "20;82;40"    "18;88;45"    "12;75;22"
  "0;92;35"     "38;102;20"   "38;78;38"    "25;68;25"
  "65;105;12"   "55;98;10"    "60;18;108"   "52;12;122"
  "58;28;122"   "44;12;132"   "82;32;140"   "78;48;152"
  "74;18;132"   "88;28;130"   "112;0;85"    "122;18;78"
  "122;8;112"   "122;28;68"   "122;38;92"   "102;18;62"
  "128;32;78"   "85;98;122"   "68;78;105"   "88;98;128"
)
# PRI/SEC assigned after JSON parse (idx comes from session ID hash)

# ── TRAFFIC LIGHT ───────────────────────────────────────────────────
tl_color() {
  local pct; pct=$(printf "%.0f" "${1:-0}" 2>/dev/null || echo "0")
  if   [ "$pct" -lt 25 ]; then printf "\x1b[38;2;0;200;80m"
  elif [ "$pct" -lt 50 ]; then printf "\x1b[38;2;235;220;40m"
  elif [ "$pct" -lt 75 ]; then printf "\x1b[38;2;255;100;0m"
  else                         printf "\x1b[38;2;210;0;0m"
  fi
}

# ── PARSE JSON (python3) ─────────────────────────────────────────────
read_json() {
  "$PYBIN" -c "
import sys, json
try:
    d = json.loads(sys.stdin.read())
    def g(obj, *keys):
        for k in keys:
            if isinstance(obj, dict) and k in obj:
                obj = obj[k]
            else:
                return None
        return obj
    print(g(d,'model','display_name') or 'Sonnet')
    print(g(d,'output_style','name') or '')
    print(g(d,'context_window','used_percentage') or 0)
    print(g(d,'context_window','context_window_size') or 200000)
    print(g(d,'rate_limits','five_hour','used_percentage') or 0)
    print(g(d,'rate_limits','seven_day','used_percentage') or 0)
    print(g(d,'rate_limits','five_hour','resets_at') or '')
    print(g(d,'rate_limits','seven_day','resets_at') or '')
    mcp = g(d,'mcp_servers')
    print(len(mcp) if isinstance(mcp, list) else 0)
    import hashlib
    sid = str(d.get('session_id',''))
    print(int(hashlib.md5(sid.encode()).hexdigest(),16) % 48)
    print(g(d,'effort','level') or '')
    print(g(d,'workspace','repo','owner') or '')
    print(g(d,'workspace','repo','name') or '')
    print(g(d,'workspace','git_worktree') or '')
    print(g(d,'pr','number') or '')
    print(g(d,'pr','url') or '')
    print(g(d,'pr','review_state') or '')
    print(g(d,'prompt_cache','expires_at') or '')
except Exception as e:
    print('Sonnet'); print(''); print(0); print(200000)
    print(0); print(0); print(''); print(''); print(0); print(0); print('')
    print(''); print(''); print(''); print(''); print(''); print(''); print('')
" <<< "$input"
}

mapfile -t parsed < <(read_json | tr -d '\r')
model_full="${parsed[0]}"
ctx_pct="${parsed[2]:-0}"
maxc="${parsed[3]:-200000}"
sess_pct="${parsed[4]:-0}"
week_pct="${parsed[5]:-0}"
sess_reset="${parsed[6]}"
week_reset="${parsed[7]}"
mcp_count="${parsed[8]:-0}"
idx="${parsed[9]:-0}"
effort="${parsed[10],,}"
[ -z "$effort" ] && effort="auto"
repo_owner="${parsed[11]}"
repo_name="${parsed[12]}"
git_wt="${parsed[13]}"
pr_num="${parsed[14]}"
pr_url="${parsed[15]}"
pr_state="${parsed[16],,}"
cache_exp="${parsed[17]}"
if [ -n "$cache_exp" ] && [ "$cache_exp" != "null" ]; then
  exp_hm=$(date -d "@${cache_exp}" +"%H:%M" 2>/dev/null || echo "--:--")
else exp_hm="--:--"; fi
PRI="\x1b[38;2;${PRI_PAL[$idx]}m"
SEC="\x1b[38;2;${SEC_PAL[$idx]}m"

{ [ -z "$maxc" ] || [ "$maxc" = "null" ] || [ "$maxc" = "0" ]; } && maxc=200000
used=$(( ctx_pct * maxc / 100 ))

# ── MODEL ───────────────────────────────────────────────────────────
CLAUDE_C="\x1b[38;2;255;100;0m"
model_name="$model_full"
case "$model_full" in
  *Opus*)   MODEL_C="\x1b[38;2;255;100;0m"  ;;
  *Fable*)  MODEL_C="\x1b[38;2;110;42;0m"  ;;
  *Sonnet*) MODEL_C="\x1b[38;2;255;150;60m" ;;
  *Haiku*)  MODEL_C="\x1b[38;2;255;195;120m";;
  *)        MODEL_C="\x1b[38;2;255;150;60m" ;;
esac

# ── EFFORT ──────────────────────────────────────────────────────────
case "$effort" in
  low)    EFF_C="\x1b[37m";                EFF="◌" ;;
  medium) EFF_C="\x1b[32m";                EFF="◔" ;;
  high)   EFF_C="\x1b[33m";                EFF="◑" ;;
  xhigh)  EFF_C="\x1b[38;5;208m";          EFF="◕" ;;
  max)    EFF_C="\x1b[38;2;210;0;0m";      EFF="●" ;;
  *)      EFF_C="\x1b[37m";                EFF="◌" ;;
esac

# ── FORMAT K/M ──────────────────────────────────────────────────────
fmt_k() {
  local n=$1
  if [ "$n" -ge 1000000 ]; then awk "BEGIN{printf \"%.0fM\",$n/1000000}"
  elif [ "$n" -ge 1000 ];   then awk "BEGIN{printf \"%.0fK\",$n/1000}"
  else echo "$n"; fi
}

# ── CONTEXT BAR (20 chars) ──────────────────────────────────────────
fill=$(( ctx_pct * 20 / 100 )); [ $fill -gt 20 ] && fill=20; [ $fill -lt 0 ] && fill=0
empty=$(( 20 - fill ))
bar_fill=""; for ((i=0; i<fill;  i++)); do bar_fill+="█"; done
bar_empty=""; for ((i=0; i<empty; i++)); do bar_empty+="─"; done

# ── AUTOCOMPACT REMAINING ───────────────────────────────────────────
autocompact=$(( maxc * 83 / 100 ))
remaining=$(( autocompact - used )); [ $remaining -lt 0 ] && remaining=0
rem_fmt=$(fmt_k $remaining)
if [ "$used" -gt $(( maxc * 60 / 100 )) ]; then REM_C="\x1b[31m"; else REM_C="$PRI"; fi

# ── FRACTION ────────────────────────────────────────────────────────
used_fmt=$(fmt_k $used); max_fmt=$(fmt_k $maxc)

# ── DATE / TIME ─────────────────────────────────────────────────────
cur_date=$(date +"%b%-d" 2>/dev/null || date +"%b%d")
cur_time=$(date +"%H:%M")

# ── RESET TIMES ─────────────────────────────────────────────────────
if [ -n "$sess_reset" ] && [ "$sess_reset" != "null" ]; then
  sess_hr=$(date -d "@${sess_reset}" +"%H:%M" 2>/dev/null || echo "??")
else sess_hr="??"; fi
if [ -n "$week_reset" ] && [ "$week_reset" != "null" ]; then
  week_day=$(date -d "@${week_reset}" +"%a" 2>/dev/null | cut -c1-2 | tr '[:lower:]' '[:upper:]' || echo "??")
  week_hr=$(date -d "@${week_reset}"  +"%H" 2>/dev/null || echo "??")
  week_rst="${week_day}${week_hr}"
else week_rst="????"; fi

# ── TRAFFIC COLORS ──────────────────────────────────────────────────
SESS_C=$(tl_color "$sess_pct"); WEEK_C=$(tl_color "$week_pct")
sess_fmt=$(printf "%.0f" "$sess_pct" 2>/dev/null || echo "0")
week_fmt=$(printf "%.0f" "$week_pct" 2>/dev/null || echo "0")

# ── FOLDER ──────────────────────────────────────────────────────────
folder=$(basename "$PWD")

# ── REPO / WORKTREE / PR SEGMENT ────────────────────────────────────
# owner/name, then /worktree when in one, then a clickable #PR when one exists.
# The #PR link is coloured by pr.review_state (reading it is free; no permission
# needed). amber = a PR exists and wants attention; dim = still a draft.
pr_link=""
if [ -n "$pr_num" ]; then
  case "$pr_state" in
    approved)          PR_C="\x1b[38;2;0;200;100m"   ;;  # green
    changes_requested) PR_C="\x1b[38;2;210;0;0m"     ;;  # red
    draft)             PR_C="\x1b[38;2;150;150;150m" ;;  # dim
    *)                 PR_C="\x1b[38;2;255;170;0m"   ;;  # amber
  esac
  pr_link="${PR_C}\x1b]8;;${pr_url}\a#${pr_num}\x1b]8;;\a${R}"
fi
repo_block=""
if [ -n "$repo_name" ]; then
  inner="${SEC}${repo_owner}/${repo_name}${R}"
  [ -n "$git_wt" ] && inner="${inner}${PRI}/${git_wt}${R}"
  if [ -n "$pr_link" ]; then
    repo_block=" ${W}[${R}${inner} ${pr_link}${W}]${R}"
  else
    repo_block=" ${W}[${R}${inner}${W}]${R}"
  fi
fi

# ── OUTPUT ──────────────────────────────────────────────────────────
printf "${W}[${R}${PRI}~/${folder}${R}${W}] [${R}${PRI}${bar_fill}${R}${SEC}${bar_empty}${R}${PRI}${ctx_pct}%%${R}${W}|${R}${SEC}${used_fmt}${R}${PRI}/${max_fmt}${R}${W}|${R}${REM_C}${rem_fmt}${R}${W}] [${R}${PRI}Exp:${R}${SEC}${exp_hm}${R}${W}] [${R}${PRI}${cur_date}${R} ${PRI}${cur_time}${R}${W}|${R}${PRI}S:${R}${SESS_C}${sess_fmt}%%${R} ${SEC}${sess_hr}${R}${W}|${R}${PRI}W:${R}${WEEK_C}${week_fmt}%%${R} ${SEC}${week_rst}${R}${W}] [${R}${CLAUDE_C}Claude${R} ${MODEL_C}${model_name}${R} ${EFF_C}${EFF}${R} ${W}]${R}${repo_block}\n"
