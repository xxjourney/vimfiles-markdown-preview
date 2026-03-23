# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal Vim configuration with cross-platform Markdown preview:
- **Windows GVim**: converts Markdown to HTML and opens in the default browser (dark mode)
- **WSL/Linux Terminal Vim**: renders in a vertical split terminal via `glow` or `python3+rich`

The single file to maintain is `vimrc`. The setup scripts (`setup.sh` / `setup.ps1`) automate first-time installation.

## Setup

**WSL/Linux (one-time):**
```bash
bash setup.sh
```

**Windows (one-time, in PowerShell):**
```powershell
.\setup.ps1
```

Both scripts install vim-plug, create `~/.vim/undodir`, link/source `vimrc`, and run `:PlugInstall`.

**Manual plugin install after editing `vimrc`:**
```
:PlugInstall   " inside Vim
```

## Architecture

All logic lives in `vimrc`:

- **Plugin**: `plasticboy/vim-markdown` (via vim-plug, loaded from `~/.vim/plugged`)
- **Markdown preview toggle**: `ToggleMarkdownPreview()` — dispatches to platform-specific renderer
  - `s:OpenBrowserPreview()` — Windows only; writes a temp Python script that converts Markdown to HTML (using `markdown` package or a regex fallback), then opens it with `cmd /c start`
  - `s:OpenTerminalPreview()` — Unix only; opens a `:terminal` split running `glow` (preferred) or `python3+rich`
  - `s:CloseMarkdownPreview()` / `s:IsMarkdownPreviewOpen()` — track the preview window via `g:markdown_preview_win`
- **Keybindings**: `F5` and `<leader>p` both call `ToggleMarkdownPreview()`
- **Auto-close**: `BufLeave` autocmd closes the preview when leaving a Markdown buffer (Unix only)

## Key details

- `<leader>` is Vim default (`\`)
- Persistent undo stored in `~/.vim/undodir` (must exist before launching Vim)
- Python path search order on Windows: `python` → `python3` → `py` (Windows Launcher)
- `glow` is expected at `~/.local/bin/glow`; the terminal preview script prepends `$HOME/.local/bin` to `PATH`
- Preview refresh on WSL requires pressing `F5` twice (close then reopen); Windows opens a new browser tab each time
