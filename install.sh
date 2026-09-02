#!/usr/bin/env bash
# install.sh — bootstrap a fresh Mac from this dotfiles repo
#
# Usage on a new machine:
#   git clone <your-dotfiles-repo-url> ~/dotfiles
#   cd ~/dotfiles && ./install.sh

set -euo pipefail

DOTFILES_DIR="$HOME/dotfiles"

echo "==> [1/5] Checking for Xcode Command Line Tools..."
if ! xcode-select -p &>/dev/null; then
  xcode-select --install
  echo "Xcode CLT install triggered. Re-run this script once that finishes."
  exit 1
fi

echo "==> [2/5] Checking for Homebrew..."
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo "==> [3/5] Installing packages from Brewfile..."
brew bundle install --file="$DOTFILES_DIR/brewfile"

echo "==> [4/5] Symlinking configs into place..."
ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
mkdir -p "$HOME/.config"
ln -sf "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"

if [ -e "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
  echo "    ~/.config/nvim already exists and is not a symlink — leaving it untouched."
  echo "    Move or remove it, then re-run this script, if you want kickstart linked in."
else
  ln -sf "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
fi

echo "==> Setting up iTerm2 Dynamic Profile (font)..."
mkdir -p "$HOME/Library/Application Support/iTerm2/DynamicProfiles"
ln -sf "$DOTFILES_DIR/iterm2/DynamicProfiles/dotfiles.json" \
  "$HOME/Library/Application Support/iTerm2/DynamicProfiles/dotfiles.json"
defaults write com.googlecode.iterm2 "Default Bookmark Guid" -string "B510D0FB-4D0B-4E7B-9F3E-9C5B7F4A1234"
echo "    Quit and reopen iTerm2 fully (Cmd+Q) for the profile and font to apply."

echo "==> [5/5] Done."
echo "Restart your terminal, or run: source ~/.zshrc"
echo "Then launch nvim once to let lazy.nvim install plugins."
