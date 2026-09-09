#!/bin/sh
# Restore this Void setup onto a machine. Run as your normal user (it uses sudo
# where needed). Every step is idempotent: re-running does no harm.
#
#   ./install.sh             # do it
#   ./install.sh --dry-run   # print what would happen, change nothing
#   ./install.sh --skip-src  # skip the xbps-src step (no discord/runner, no
#                            #   void-packages clone/bootstrap)
# Flags may be combined and given in any order.
set -eu

REPO="$(cd "$(dirname "$0")" && pwd)"
DRY=0
SKIP_SRC=0
for arg in "$@"; do
  case "$arg" in
    --dry-run)  DRY=1 ;;
    --skip-src) SKIP_SRC=1 ;;
    -h|--help)  echo "usage: install.sh [--dry-run] [--skip-src]"; exit 0 ;;
    *) echo "unknown option: $arg (try --help)" >&2; exit 2 ;;
  esac
done

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
if [ "$SKIP_SRC" = 1 ]; then
  echo "  (skipped: --skip-src)"
elif grep -qvE '^\s*(#|$)' "$REPO/packages-src.txt" 2>/dev/null; then
  run "'$REPO/build-src.sh'"
fi

say "4/7  Symlink dotfiles with stow (config, home, local)"
command -v stow >/dev/null || run "sudo xbps-install -y stow"
# --adopt resolves conflicts with stock files base-system ships (e.g. ~/.bashrc):
# it pulls the stock file into the repo, then `git checkout` restores our tracked
# version, so the resulting symlink points at the correct content.
run "stow --no-folding --adopt -R -t '$HOME' -d '$REPO' config home local"
run "git -C '$REPO' checkout -- config home local"

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
