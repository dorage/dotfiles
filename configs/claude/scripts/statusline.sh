#!/bin/bash
# Claude Code statusLine script.
#
# Segments: dir, git branch/status, Claude Code model name, context usage.
#
# Colors are fixed xterm-256 numbers applied via ANSI 256-color escapes.
# They were originally taken from a Powerlevel10k config that has since been
# removed; this script does not read or depend on any shell prompt config.

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // empty')
[ -z "$cwd" ] && cwd=$(pwd)
ctx_used=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // 0')

# ---- colors (xterm-256 codes) ----
c_reset="\033[0m"
c_dir="\033[38;5;31m"            # parent directories
c_dir_anchor="\033[1;38;5;39m"   # current directory (bold)
c_git_clean="\033[38;5;76m"      # clean branch
c_git_modified="\033[38;5;178m" # staged/unstaged changes
c_git_untracked="\033[38;5;39m" # untracked files
c_meta="\033[38;5;244m"          # separators and labels
c_model="\033[38;5;250m"         # model name and token counts

# ---- dir segment ----
display_cwd=$(echo "$cwd" | sed "s|^$HOME|~|")
parent=$(dirname "$display_cwd")
base=$(basename "$display_cwd")
if [ "$parent" = "." ] || [ "$parent" = "/" ] || [ "$display_cwd" = "~" ]; then
  dir_display="${c_dir_anchor}${base}${c_reset}"
else
  dir_display="${c_dir}${parent}/${c_dir_anchor}${base}${c_reset}"
fi

# ---- vcs (git) segment ----
git_display=""
if git -C "$cwd" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
  [ -z "$branch" ] && branch=$(git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)

  staged=$(git -C "$cwd" --no-optional-locks diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
  unstaged=$(git -C "$cwd" --no-optional-locks diff --numstat 2>/dev/null | wc -l | tr -d ' ')
  untracked=$(git -C "$cwd" --no-optional-locks ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

  if [ "$staged" != "0" ] || [ "$unstaged" != "0" ]; then
    branch_color="$c_git_modified"
  else
    branch_color="$c_git_clean"
  fi

  git_display=" ${c_meta}on ${branch_color}${branch}${c_reset}"
  [ "$staged" != "0" ] && git_display="${git_display} ${c_git_modified}+${staged}${c_reset}"
  [ "$unstaged" != "0" ] && git_display="${git_display} ${c_git_modified}!${unstaged}${c_reset}"
  [ "$untracked" != "0" ] && git_display="${git_display} ${c_git_untracked}?${untracked}${c_reset}"
fi

# ---- context usage segment ----
# Compact token counts, e.g. "72.3k/1.0M". Falls back to a plain count when the
# context window size is unknown (older CLI versions omit context_window).
fmt_tokens() {
  awk -v n="$1" 'BEGIN {
    if (n >= 1000000) printf "%.1fM", n / 1000000;
    else if (n >= 1000) printf "%.1fk", n / 1000;
    else printf "%d", n;
  }'
}

if [ "$ctx_size" != "0" ]; then
  ctx_display="${c_model}$(fmt_tokens "$ctx_used")${c_meta}/$(fmt_tokens "$ctx_size")${c_reset}"
else
  ctx_display="${c_model}$(fmt_tokens "$ctx_used")${c_reset}"
fi

printf "${dir_display}${git_display}  ${c_meta}\xe2\x80\xba${c_reset} ${c_model}${model}${c_reset}  ${c_meta}\xe2\x80\xba${c_reset} ${ctx_display}\n"
