-- Seamless <C-hjkl> navigation between Neovim splits and tmux panes.
--
-- The matching tmux side lives in `tmux.conf` in this dotfiles repo: tmux
-- inspects the process running in the pane and, if it is Neovim, forwards the
-- key instead of switching panes itself. Neovim then moves to a split, or --
-- when there is no split that way -- asks tmux to switch panes.
--
-- See https://github.com/christoomey/vim-tmux-navigator

local function gh(repo) return 'https://github.com/' .. repo end

-- Must be set before the plugin is sourced: it only defaults these when unset.
-- Write the buffer when navigating away from Neovim into another tmux pane.
vim.g.tmux_navigator_save_on_switch = 1

-- Don't navigate out of a zoomed pane -- unzoom deliberately instead.
vim.g.tmux_navigator_disable_when_zoomed = 1

vim.pack.add { gh 'christoomey/vim-tmux-navigator' }

-- The plugin installs its own <C-hjkl> and <C-\> mappings on load, which happens
-- after `lua/keymaps.lua` runs -- so they replace the plain `<C-w>` window
-- mappings defined there. We keep those defaults rather than redefining them
-- here: they also special-case fzf running in a `:terminal` buffer, and work
-- around netrw's own <C-l>. Set `vim.g.tmux_navigator_no_mappings = 1` above the
-- `vim.pack.add` call if you ever want to define your own instead.

-- vim: ts=2 sts=2 sw=2 et
