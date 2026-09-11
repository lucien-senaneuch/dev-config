#!/usr/bin/env bash
# install.sh — bootstrap a machine from this dotfiles repo.
#
# Supports macOS and Linux (tested target: Ubuntu on WSL2). Both platforms use
# Homebrew as the package manager so a single brewfile serves both; on Linux
# that's Linuxbrew in /home/linuxbrew/.linuxbrew.
#
# Usage on a new machine:
#   git clone <your-dotfiles-repo-url> ~/dotfiles
#   cd ~/dotfiles && ./install.sh
#
# Safe to re-run: every step checks before it acts.

set -euo pipefail

# Resolve the repo from this script's own location, so the clone can live
# anywhere (~/dotfiles on the Mac, /home/<user>/dotfiles on WSL, ...).
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Platform detection ---
IS_WSL=false
case "$(uname -s)" in
  Darwin) OS=macos ;;
  Linux)
    OS=linux
    if [ -n "${WSL_DISTRO_NAME:-}" ] || grep -qi microsoft /proc/version 2>/dev/null; then
      IS_WSL=true
    fi
    ;;
  *)
    echo "Unsupported platform: $(uname -s). This script handles macOS and Linux." >&2
    exit 1
    ;;
esac

PLATFORM_LABEL="$OS"
[ "$IS_WSL" = true ] && PLATFORM_LABEL="linux (WSL2)"

STEP=0
TOTAL=6
step() {
  STEP=$((STEP + 1))
  echo "==> [$STEP/$TOTAL] $1"
}

echo "==> Bootstrapping dotfiles from $DOTFILES_DIR on $PLATFORM_LABEL"

# ---------------------------------------------------------------------------
step "Installing build prerequisites..."
if [ "$OS" = macos ]; then
  if ! xcode-select -p &>/dev/null; then
    xcode-select --install
    echo "Xcode CLT install triggered. Re-run this script once that finishes."
    exit 1
  fi
  echo "    Xcode Command Line Tools present."
else
  # Homebrew on Linux needs a compiler and a few basics; zsh itself comes from
  # apt so that chsh can point at a path already listed in /etc/shells.
  #
  # A fresh WSL2 Ubuntu runs unattended-upgrades in the background on first
  # boot, which holds /var/lib/dpkg/lock-frontend. Lock::Timeout makes apt wait
  # for it (up to 10 min) instead of failing with "Could not get lock".
  APT_OPTS=(-o DPkg::Lock::Timeout=600)
  if ! sudo apt-get "${APT_OPTS[@]}" update ||
     ! sudo apt-get "${APT_OPTS[@]}" install -y build-essential procps curl file git zsh unzip; then
    echo
    echo "apt failed. If it was the dpkg lock, something else is mid-install —" >&2
    echo "see what holds it, wait for it to finish, then re-run this script:" >&2
    echo "  ps aux | grep -E 'apt|dpkg|unattended' | grep -v grep" >&2
    exit 1
  fi
fi

# ---------------------------------------------------------------------------
step "Installing Homebrew..."
if ! command -v brew &>/dev/null; then
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
# Put brew on PATH for the rest of this script, wherever it landed.
for BREW_BIN in /opt/homebrew/bin/brew /usr/local/bin/brew \
                /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
  if [ -x "$BREW_BIN" ]; then
    eval "$("$BREW_BIN" shellenv)"
    break
  fi
done
if ! command -v brew &>/dev/null; then
  echo "Homebrew install finished but 'brew' is not on PATH — aborting." >&2
  exit 1
fi
echo "    Using brew at $(command -v brew)"

# ---------------------------------------------------------------------------
step "Installing packages from brewfile..."
# The brewfile guards macOS-only casks with `if OS.mac?`, so the same file works
# on both platforms.
brew bundle install --file="$DOTFILES_DIR/brewfile"

# ---------------------------------------------------------------------------
step "Symlinking configs into place..."
ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
mkdir -p "$HOME/.config"
ln -sf "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"
ln -sf "$DOTFILES_DIR/tmux.conf" "$HOME/.tmux.conf"

if [ -e "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
  echo "    ~/.config/nvim already exists and is not a symlink — leaving it untouched."
  echo "    Move or remove it, then re-run this script, if you want kickstart linked in."
else
  # -n matters: without it, a re-run follows the existing symlink and creates a
  # recursive nvim/nvim link *inside* the repo instead of replacing the link.
  ln -sfn "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
fi

# ---------------------------------------------------------------------------
step "Applying platform-specific setup..."
if [ "$OS" = macos ]; then
  echo "    iTerm2 Dynamic Profile (font, window size)..."
  mkdir -p "$HOME/Library/Application Support/iTerm2/DynamicProfiles"
  ln -sf "$DOTFILES_DIR/iterm2/DynamicProfiles/dotfiles.json" \
    "$HOME/Library/Application Support/iTerm2/DynamicProfiles/dotfiles.json"
  defaults write com.googlecode.iterm2 "Default Bookmark Guid" \
    -string "B510D0FB-4D0B-4E7B-9F3E-9C5B7F4A1234"
  echo "    Quit and reopen iTerm2 fully (Cmd+Q) for the profile and font to apply."
else
  # Ubuntu logs you into bash by default.
  if [ "$(basename "${SHELL:-}")" != "zsh" ]; then
    echo "    Setting zsh as the login shell (needs your password)..."
    chsh -s "$(command -v zsh)" || \
      echo "    chsh failed — run it yourself: chsh -s \$(command -v zsh)"
  else
    echo "    Login shell is already zsh."
  fi

  # claude-code ships as a cask on macOS; on Linux it comes from npm (node is
  # in the brewfile, so this needs no sudo).
  if ! command -v claude &>/dev/null && command -v npm &>/dev/null; then
    echo "    Installing claude-code via npm..."
    npm install -g @anthropic-ai/claude-code
  fi

  if [ "$IS_WSL" = true ]; then
    # win32yank makes nvim's clipboard instant; without it nvim/options.lua
    # falls back to clip.exe + powershell, which works but lags on paste.
    if ! command -v win32yank.exe &>/dev/null; then
      echo "    Optional: install win32yank for a faster nvim clipboard —"
      echo "      winget install --id equalsraf.win32yank    (run in Windows)"
    fi
    echo "    Font: install MesloLGS Nerd Font on the WINDOWS side and select it"
    echo "      in Windows Terminal, otherwise Starship's icons render as boxes:"
    echo "      https://github.com/ryanoasis/nerd-fonts/releases (Meslo.zip)"
  fi
fi

# ---------------------------------------------------------------------------
step "Verifying the tools this config needs..."
# The classic cross-machine failure: Ubuntu's apt ships Neovim 0.9.5, which has
# no vim.pack, so init.lua aborts with "Invalid 'event': 'PackChanged'" and NO
# plugins load at all (no neo-tree, no telescope). Homebrew's nvim must win.
if ! command -v nvim &>/dev/null; then
  echo "    WARNING: nvim is not on PATH."
else
  NVIM_VER="$(nvim --version | head -1 | sed -E 's/^NVIM v([0-9]+\.[0-9]+).*/\1/')"
  NVIM_MAJOR="${NVIM_VER%%.*}"
  NVIM_MINOR="${NVIM_VER##*.}"
  if [ "$NVIM_MAJOR" -eq 0 ] && [ "$NVIM_MINOR" -lt 12 ]; then
    echo "    WARNING: $(command -v nvim) is v$NVIM_VER, but this config needs 0.12+."
    echo "      Ubuntu's apt package is 0.9.5 and will load zero plugins."
    echo "      Fix: sudo apt remove neovim, then open a new shell so brew's nvim wins."
  else
    echo "    nvim v$NVIM_VER at $(command -v nvim)"
  fi
fi

MISSING=""
for TOOL in tmux starship eza bat fzf zoxide rg fd lazygit tree-sitter git make; do
  command -v "$TOOL" &>/dev/null || MISSING="$MISSING $TOOL"
done
if [ -n "$MISSING" ]; then
  echo "    WARNING: not found on PATH:$MISSING"
  echo "      If you just ran this script, open a new shell and re-check —"
  echo "      brew's bin directory only joins PATH once ~/.zshrc has run."
else
  echo "    All expected CLI tools are on PATH."
fi

# ---------------------------------------------------------------------------
echo "==> Done."
echo "Restart your terminal, or run: source ~/.zshrc"
echo "Then launch nvim once to let the plugin manager install plugins."
