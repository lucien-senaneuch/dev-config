# ~/.zshrc

# --- Homebrew (works on both Apple Silicon and Intel Macs) ---
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
BREW_PREFIX="$(brew --prefix)"

# --- History ---
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt APPEND_HISTORY

# --- Editor ---
export EDITOR="nvim"
export VISUAL="nvim"

# --- Aliases ---
alias vim="nvim"
alias ls="eza --icons --group-directories-first"
alias ll="eza -la --icons --group-directories-first"
alias lt="eza --tree --icons --level=2"
alias cat="bat --style=plain"

# --- Zsh plugins (installed via brewfile, no framework needed) ---
source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# --- Tool integrations ---
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
source <(fzf --zsh)
