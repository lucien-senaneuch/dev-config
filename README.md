# dotfiles

zsh + starship + tmux + neovim (kickstart-modular), shared between macOS and
Ubuntu on WSL2.

## Install

```sh
git clone <this-repo> ~/dotfiles
cd ~/dotfiles && ./install.sh
```

`install.sh` detects the platform and is safe to re-run. Both platforms use
Homebrew so one `brewfile` serves both — on Linux that's Linuxbrew in
`/home/linuxbrew/.linuxbrew`, installed by the script along with the
`build-essential` prerequisites it needs.

## What differs per platform

| | macOS | Ubuntu on WSL2 |
|---|---|---|
| Packages | Homebrew + casks | Linuxbrew (casks skipped via `if OS.mac?`) |
| Terminal | iTerm2, configured by a Dynamic Profile | Windows Terminal (configured on Windows) |
| Font | `font-meslo-lg-nerd-font` cask | install Meslo Nerd Font **on Windows** |
| Clipboard | `pbcopy` | `clip.exe`, or win32yank in nvim |
| Login shell | already zsh | `chsh` to zsh, done by the script |

Everything else — `.zshrc`, `tmux.conf`, `starship.toml`, the whole `nvim/`
tree — is the same file on both machines, with the platform differences handled
inside them at runtime.

## WSL2: two manual steps on the Windows side

The script can't do these from inside WSL:

1. **Font** — download [Meslo Nerd Font](https://github.com/ryanoasis/nerd-fonts/releases)
   (`Meslo.zip`), install it in Windows, and select `MesloLGS Nerd Font` in
   Windows Terminal. Without it Starship's icons render as boxes.
2. **win32yank** (optional) — `winget install --id equalsraf.win32yank`.
   Neovim uses it when present; otherwise it falls back to `clip.exe` +
   powershell, which works but adds ~200ms to each paste.

## Adding a package

Add it to `brewfile`, then re-run `./install.sh` (or `brew bundle install
--file=brewfile`). Keep macOS-only apps inside the `if OS.mac?` block at the
bottom so the Linux machine skips them.

## Troubleshooting

**Plugins don't load / neo-tree is missing on Linux.** Check the Neovim version
first — this config uses `vim.pack`, which needs 0.12+:

```sh
nvim --version | head -1 && command -v nvim
```

Ubuntu's apt package is 0.9.5. On it, `init.lua` aborts with
`E5113: Invalid 'event': 'PackChanged'` and **no** plugins load at all. Remove
it (`sudo apt remove neovim`) so Homebrew's nvim is the one on PATH, then open a
new shell. `./install.sh` checks this for you at the end.

**`Could not get lock /var/lib/dpkg/lock-frontend`.** Something else is using
apt — on a fresh WSL2 install that's normally `unattended-upgrades` on first
boot. The script waits up to 10 minutes for the lock; if it still fails, see
what holds it and retry once it's gone:

```sh
ps aux | grep -E 'apt|dpkg|unattended' | grep -v grep
```

**Tools "missing" right after install.** Homebrew's `bin` only joins `PATH`
when `~/.zshrc` runs. Open a new shell, or `source ~/.zshrc`.

**Icons show as boxes.** The Nerd Font isn't installed or isn't selected in
Windows Terminal — see the WSL2 section above.
