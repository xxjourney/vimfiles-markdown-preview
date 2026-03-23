# Setup script for Windows GVim
# Run in PowerShell: .\setup.ps1

$ErrorActionPreference = "Stop"
$VimfilesDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# ── 1. Check GVim ────────────────────────────────────────────────────────────
if (-not (Get-Command gvim -ErrorAction SilentlyContinue)) {
    Write-Warning "GVim not found. Download from https://www.vim.org/download.php and re-run."
    exit 1
}
Write-Host "==> GVim found: $(gvim --version 2>&1 | Select-Object -First 1)"

# ── 2. Check Python ──────────────────────────────────────────────────────────
$python = $null
foreach ($cmd in @("python", "python3", "py")) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
        $python = $cmd
        break
    }
}
if (-not $python) {
    Write-Warning "Python not found. Install from https://www.python.org/downloads/ (check 'Add to PATH') and re-run."
    exit 1
}
Write-Host "==> Python found: $(& $python --version)"

# ── 3. Install markdown package ──────────────────────────────────────────────
Write-Host "==> Installing Python markdown packages..."
& $python -m pip install --quiet markdown pymdown-extensions
Write-Host "    markdown + pymdown-extensions installed."

# ── 4. Install vim-plug ──────────────────────────────────────────────────────
Write-Host "==> Installing vim-plug..."
$plugDir = "$env:USERPROFILE\vimfiles\autoload"
New-Item -ItemType Directory -Force -Path $plugDir | Out-Null
$plugUrl = "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
Invoke-WebRequest -Uri $plugUrl -OutFile "$plugDir\plug.vim" -UseBasicParsing
Write-Host "    plug.vim installed to $plugDir"

# ── 5. Create undo directory ─────────────────────────────────────────────────
Write-Host "==> Creating undo directory..."
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.vim\undodir" | Out-Null

# ── 6. Set up _vimrc ─────────────────────────────────────────────────────────
$vimrc    = "$env:USERPROFILE\_vimrc"
$srcLine  = "source " + ($VimfilesDir -replace '\\', '/') + "/vimrc"

Write-Host "==> Setting up _vimrc..."
if (Test-Path $vimrc) {
    $existing = Get-Content $vimrc -Raw
    if ($existing -notmatch [regex]::Escape("vimfiles/vimrc")) {
        Add-Content -Path $vimrc -Value "`n$srcLine"
        Write-Host "    Appended source line to existing _vimrc."
    } else {
        Write-Host "    _vimrc already sources vimfiles/vimrc, skipping."
    }
} else {
    Set-Content -Path $vimrc -Value $srcLine
    Write-Host "    Created $vimrc with source line."
}

# ── 7. Install Vim plugins ───────────────────────────────────────────────────
Write-Host "==> Installing Vim plugins (PlugInstall)..."
Start-Process gvim -ArgumentList "+PlugInstall", "+qall" -Wait
Write-Host "    Plugins installed."

Write-Host ""
Write-Host "Setup complete!" -ForegroundColor Green
Write-Host "Open a .md file in GVim and press F5 to preview in your browser."
Write-Host ""
Write-Host "Optional: to symlink _vimrc instead of sourcing it (requires Admin):" -ForegroundColor Yellow
Write-Host "  mklink `"$env:USERPROFILE\_vimrc`" `"$VimfilesDir\vimrc`""
