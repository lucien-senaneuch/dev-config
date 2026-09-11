#!/usr/bin/env bash
# doctor.sh — report why this config might not be loading.
# Run it on the machine that misbehaves:  ./doctor.sh
# It only reads state; it changes nothing.

say() { printf '%-24s %s\n' "$1" "$2"; }
# macOS has no coreutils `timeout`; fall back to running the command bare.
run_to() { local t="$1"; shift; if command -v timeout >/dev/null 2>&1; then timeout "$t" "$@"; else "$@"; fi; }
hr()  { printf -- '--- %s %s\n' "$1" "$(printf '%.0s-' $(seq 1 $((50 - ${#1}))))"; }

hr "environment"
say "platform"   "$(uname -s) $(uname -r)"
say "WSL"        "${WSL_DISTRO_NAME:-$(grep -qi microsoft /proc/version 2>/dev/null && echo yes || echo no)}"
say "shell"      "$SHELL (running under ${0##*/})"
say "brew"       "$(command -v brew || echo 'NOT FOUND')"

hr "neovim"
if command -v nvim >/dev/null; then
  say "nvim path"    "$(command -v nvim)"
  say "nvim version" "$(nvim --version | head -1)"
  # Every nvim on PATH, in order — a second one (e.g. apt's in /usr/bin) can
  # shadow brew's. Scanning PATH directly avoids locale-dependent `type -a`.
  ALL_NVIM=""
  IFS=':' read -ra PATH_DIRS <<< "$PATH"
  for d in "${PATH_DIRS[@]}"; do
    [ -x "$d/nvim" ] && ALL_NVIM="$ALL_NVIM $d/nvim"
  done
  say "all nvim on PATH" "${ALL_NVIM:-<none>}"
else
  say "nvim" "NOT FOUND ON PATH"
fi

hr "where nvim looks for config"
for v in XDG_CONFIG_HOME XDG_DATA_HOME NVIM_APPNAME VIMINIT; do
  say "\$$v" "${!v:-<unset, fine>}"
done
if command -v nvim >/dev/null; then
  CFG="$(nvim --headless '+lua io.write(vim.fn.stdpath("config"))' +qa 2>/dev/null)"
  DATA="$(nvim --headless '+lua io.write(vim.fn.stdpath("data"))' +qa 2>/dev/null)"
  say "stdpath('config')" "$CFG"
  say "stdpath('data')"   "$DATA"
  if [ -L "$CFG" ]; then
    say "  it is"  "a symlink -> $(readlink "$CFG")"
  elif [ -d "$CFG" ]; then
    say "  it is"  "a REAL DIRECTORY (not a symlink to your repo!)"
  else
    say "  it is"  "MISSING — nvim is loading no config at all"
  fi
  say "  init.lua"    "$([ -f "$CFG/init.lua" ] && echo present || echo MISSING)"
  say "  lua/pack.lua" "$([ -f "$CFG/lua/pack.lua" ] && echo present || echo MISSING)"
fi

hr "installed plugins"
PLUGDIR="${DATA:-$HOME/.local/share/nvim}/site/pack/core/opt"
if [ -d "$PLUGDIR" ]; then
  say "plugin dir" "$PLUGDIR"
  say "count"      "$(ls -1 "$PLUGDIR" | wc -l | tr -d ' ') (expected 22)"
  ls -1 "$PLUGDIR" | tr '\n' ' ' | fold -s -w 76 | sed 's/^/    /'
else
  say "plugin dir" "$PLUGDIR does NOT exist — nothing was ever installed"
fi

hr "startup errors (nvim --headless +qa)"
if command -v nvim >/dev/null; then
  ERR="$(run_to 120 nvim --headless '+qa' 2>&1 | grep -vE '^\s*$' | head -20)"
  [ -n "$ERR" ] && echo "$ERR" | sed 's/^/    /' || echo "    (none — config loaded clean)"
fi

hr "build prerequisites"
for t in git make gcc cc unzip curl tree-sitter node; do
  say "$t" "$(command -v "$t" || echo 'NOT FOUND')"
done

hr "can it reach github"
if command -v git >/dev/null; then
  if run_to 25 git ls-remote --exit-code https://github.com/nvim-lua/plenary.nvim HEAD >/dev/null 2>&1; then
    say "github.com" "reachable"
  else
    say "github.com" "UNREACHABLE — vim.pack cannot clone plugins"
  fi
fi
