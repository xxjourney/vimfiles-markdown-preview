#!/usr/bin/env bash
# Setup script for WSL / Linux

set -e

VIMFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Installing vim-plug..."
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

echo "==> Installing glow..."
mkdir -p ~/.local/bin
GLOW_URL="https://github.com/charmbracelet/glow/releases/download/v2.1.1/glow_2.1.1_Linux_x86_64.tar.gz"
curl -fsSL "$GLOW_URL" | tar -xz -C /tmp glow_2.1.1_Linux_x86_64/glow
mv /tmp/glow_2.1.1_Linux_x86_64/glow ~/.local/bin/glow
chmod +x ~/.local/bin/glow
echo "    glow installed: $(~/.local/bin/glow --version)"

echo "==> Creating undo directory..."
mkdir -p ~/.vim/undodir

echo "==> Symlinking vimrc..."
ln -sf "$VIMFILES_DIR/vimrc" ~/.vimrc
echo "    ~/.vimrc -> $VIMFILES_DIR/vimrc"

echo "==> Installing Vim plugins..."
vim +PlugInstall +qall

echo ""
echo "Done. Open a .md file in Vim and press F5 to preview."
