#!/bin/sh
# Restore this Void setup onto a machine. Run as your normal user (it uses sudo
# where needed). Every step is idempotent: re-running does no harm.
#
#   ./install.sh            # do it
#   ./install.sh --dry-run  # print what would happen, change nothing
set -eu

REPO="$(cd "$(dirname "$0")" && pwd)"
DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1

run() { if [ "$DRY" = 1 ]; then echo "  [dry] $*"; else echo "  + $*"; sh -c "$*"; fi; }
say() { printf '\n== %s ==\n' "$1"; }

[ "$(id -u)" -eq 0 ] && { echo "Run as your normal user, not root."; exit 1; }
command -v xbps-install >/dev/null || { echo "This is for Void Linux (xbps not found)."; exit 1; }

say "1/7  Repo config (mirror + xbps.d), then sync"
for f in "$REPO"/etc/xbps.d/*.conf; do
  [ -e "$f" ] && run "sudo cp -v '$f' /etc/xbps.d/"
done
run "sudo xbps-install -Sy"

say "2/7  Packages (official repos)"
# packages.txt is bare pkg names, one per line, comments (#) allowed
PKGS="$(grep -vE '^\s*(#|$)' "$REPO/packages.txt" | tr '\n' ' ')"
run "sudo xbps-install -y $PKGS"

say "3/7  Non-repo packages via xbps-src (discord, runner)"
if grep -qvE '^\s*(#|$)' "$REPO/packages-src.txt" 2>/dev/null; then
  run "'$REPO/build-src.sh'"
fi

say "4/7  Symlink dotfiles with stow (config, home, local)"
command -v stow >/dev/null || run "sudo xbps-install -y stow"
for pkg in config home local; do
  [ -d "$REPO/$pkg" ] && run "stow --no-folding -t '$HOME' -d '$REPO' -R '$pkg'"
done

say "5/7  Enable runit services"
while IFS= read -r s; do
  [ -z "$s" ] && continue
  case "$s" in \#*) continue ;; esac
  if [ -d "/etc/sv/$s" ]; then
    run "sudo ln -sfn '/etc/sv/$s' '/var/service/$s'"
  else
    echo "  ! /etc/sv/$s missing (package not installed?) - skipping"
  fi
done < "$REPO/services.txt"

say "6/7  Curated /etc files (tlp, lightdm)"
[ -e "$REPO/etc/tlp.conf" ] && run "sudo cp -v '$REPO/etc/tlp.conf' /etc/tlp.conf"
for f in "$REPO"/etc/lightdm/*.conf; do
  [ -e "$f" ] && run "sudo cp -v '$f' /etc/lightdm/"
done

say "7/7  Done"
cat <<'EOF'
  Manual follow-ups (see README.md): reinstall Claude Code, `gh auth login`,
  reinstall VSCode extensions, and unlock/recreate the gnome-keyring.
EOF
