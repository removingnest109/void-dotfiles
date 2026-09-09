#!/bin/sh
# Copy the curated config/home/local/etc trees from the live system into the repo.
# Called by sync.sh (which handles packages.txt/services.txt separately).
# Curation rules live HERE - edit this list to track more or less.
set -eu
REPO="$(cd "$(dirname "$0")" && pwd)"
CFG="$HOME/.config"

rm -rf "$REPO/config" "$REPO/home" "$REPO/local" "$REPO/etc"
mkdir -p "$REPO"/config/.config "$REPO"/home \
         "$REPO"/local/.local/bin "$REPO"/local/.local/share \
         "$REPO"/etc/xbps.d "$REPO"/etc/lightdm

# ---- ~/.config (curated: real config, no app caches/state/secrets) ----
CFG_INCLUDE="bspwm sxhkd rofi alacritty fastfetch gtk-3.0 Thunar xfce4 Mousepad menus git desktop-directories mimeapps.list user-dirs.dirs user-dirs.locale QtProject.conf"
for item in $CFG_INCLUDE; do
  [ -e "$CFG/$item" ] && cp -a "$CFG/$item" "$REPO/config/.config/"
done
# VSCode: settings only (its dir is 167M of cache otherwise)
if [ -d "$CFG/Code - OSS/User" ]; then
  mkdir -p "$REPO/config/.config/Code - OSS/User"
  for f in settings.json keybindings.json; do
    [ -e "$CFG/Code - OSS/User/$f" ] && cp -a "$CFG/Code - OSS/User/$f" "$REPO/config/.config/Code - OSS/User/"
  done
  [ -d "$CFG/Code - OSS/User/snippets" ] && cp -a "$CFG/Code - OSS/User/snippets" "$REPO/config/.config/Code - OSS/User/"
fi

# ---- home dotfiles ----
for f in .bashrc .bash_profile .profile .xinitrc .Xresources .gitconfig .inputrc .bash_logout .vimrc; do
  [ -e "$HOME/$f" ] && cp -a "$HOME/$f" "$REPO/home/"
done

# ---- ~/.local (curated: scripts + desktop entries; NOT the claude install, keyrings, or state) ----
for e in "$HOME"/.local/bin/*; do
  [ -e "$e" ] || continue
  [ "$(basename "$e")" = "claude" ] && continue
  cp -a "$e" "$REPO/local/.local/bin/"
done
for d in applications icons desktop-directories; do
  [ -e "$HOME/.local/share/$d" ] && cp -a "$HOME/.local/share/$d" "$REPO/local/.local/share/"
done

# ---- curated /etc (world-readable) ----
cp -a /etc/xbps.d/*.conf "$REPO/etc/xbps.d/" 2>/dev/null || true
[ -e /etc/tlp.conf ] && cp -a /etc/tlp.conf "$REPO/etc/"
for f in /etc/lightdm/*.conf; do [ -e "$f" ] && cp -a "$f" "$REPO/etc/lightdm/"; done
