# ~/.zshrc — shared between macOS and Linux/WSL2

# --- Homebrew (Apple Silicon, Intel Mac, or Linuxbrew) ---
for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew \
             /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
  if [[ -x "$_brew" ]]; then
    eval "$("$_brew" shellenv)"
    break
  fi
done
unset _brew
BREW_PREFIX="${HOMEBREW_PREFIX:-/usr/local}"

# --- Completions ---
autoload -Uz compinit && compinit

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
# Guarded so a half-installed machine still gets a working shell.
alias vim="nvim"
if (( $+commands[eza] )); then
  alias ls="eza --icons --group-directories-first"
  alias ll="eza -la --icons --group-directories-first"
  alias lt="eza --tree --icons --level=2"
else
  alias ll="ls -la"
fi
# Debian/Ubuntu ship bat as `batcat` when it's installed from apt rather than brew.
if (( $+commands[bat] )); then
  alias cat="bat --style=plain"
elif (( $+commands[batcat] )); then
  alias cat="batcat --style=plain"
fi
alias cc="claude"
if (( $+commands[kubectl] )); then
  alias k="kubectl"
  source <(kubectl completion zsh)
  compdef k=kubectl
fi

# --- Zsh plugins (installed via brewfile, no framework needed) ---
# Falls back to the distro package paths (/usr/share/...) if brew didn't install them.
for _plugin in zsh-autosuggestions zsh-syntax-highlighting; do
  for _dir in "$BREW_PREFIX/share/$_plugin" "/usr/share/$_plugin" "/usr/share/zsh/plugins/$_plugin"; do
    if [[ -r "$_dir/$_plugin.zsh" ]]; then
      source "$_dir/$_plugin.zsh"
      break
    fi
  done
done
unset _plugin _dir

# --- Tool integrations ---
(( $+commands[starship] )) && eval "$(starship init zsh)"
(( $+commands[zoxide] ))   && eval "$(zoxide init zsh)"
(( $+commands[fzf] ))      && source <(fzf --zsh)

# --- WSL2 ---
if [[ -n "$WSL_DISTRO_NAME" ]] || grep -qi microsoft /proc/version 2>/dev/null; then
  # Windows interop gives us clip.exe/explorer.exe; alias them to the macOS
  # names so the same muscle memory works on both machines.
  alias open="explorer.exe"
  alias pbcopy="clip.exe"
  alias pbpaste="powershell.exe -NoProfile -Command Get-Clipboard"
fi

# --- Tmux integration
if [ -z "$TMUX" ] && [ -n "$PS1" ] && (( $+commands[tmux] )); then
  tmux attach -t main || tmux new -s main
fi

export DOTNET_CLI_UI_LANGUAGE=en
export GPG_TTY=$(tty)
