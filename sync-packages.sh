#!/bin/sh
# Refresh the generated manifests FROM this machine. Configs are NOT copied here:
# this repo is stow-managed, so ~/.config, home dotfiles and ~/.local are symlinks
# INTO the repo -- editing them already updates the repo. This script only regenerates
# the things that aren't files in the repo: the package and service lists.
set -eu
REPO="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO"

echo ">> packages.txt (official repos; xbps-src packages stay in packages-src.txt)"
xbps-query -m | while read -r p; do xbps-uhelper getpkgname "$p"; done | sort -u > packages.txt
for p in stow git; do grep -qx "$p" packages.txt || echo "$p" >> packages.txt; done
if [ -s packages-src.txt ]; then
  grep -vE '^\s*(#|$)' packages-src.txt | sort -u > .src.tmp
  grep -vxf .src.tmp packages.txt > .pkg.tmp && mv .pkg.tmp packages.txt
  rm -f .src.tmp
fi
sort -u -o packages.txt packages.txt

echo ">> services.txt (base ones like dbus/udevd excluded)"
for s in $(ls /var/service); do
  case "$s" in udevd|dbus|agetty-tty*) : ;; *) echo "$s" ;; esac
done | sort > services.txt

echo
echo ">> git status:"
git -C "$REPO" status --short
echo
echo "Config edits are already staged via symlinks. Review, then:"
echo "  git -C $REPO add -A && git -C $REPO commit -m 'sync' && git -C $REPO push"
