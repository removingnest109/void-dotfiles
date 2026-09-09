#!/bin/sh
# Refresh the captured state FROM this machine so the repo doesn't drift.
# Regenerates packages.txt + services.txt and re-copies the tracked config/etc
# trees, then shows you the git diff to review before committing.
set -eu
REPO="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO"

echo ">> packages.txt"
xbps-query -m | while read -r p; do xbps-uhelper getpkgname "$p"; done | sort -u > packages.txt
for p in stow git; do grep -qx "$p" packages.txt || echo "$p" >> packages.txt; done
sort -u -o packages.txt packages.txt

echo ">> services.txt"
for s in $(ls /var/service); do
  case "$s" in udevd|dbus|agetty-tty*) : ;; *) echo "$s" ;; esac
done | sort > services.txt

echo ">> re-copying tracked config/home/local/etc from live system"
# Reuse the original builder so curation stays in one place.
if [ -x "$REPO/build-content.sh" ]; then "$REPO/build-content.sh"; fi

echo
echo ">> git status:"
git -C "$REPO" status --short
echo
echo "Review, then:  git -C $REPO add -A && git -C $REPO commit -m 'sync' && git -C $REPO push"
