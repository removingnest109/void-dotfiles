#!/bin/sh
# Build + install the packages that aren't in the official Void repos
# (see packages-src.txt) from source via xbps-src / void-packages.
# Idempotent: skips the clone/bootstrap if already done.
set -eu
REPO="$(cd "$(dirname "$0")" && pwd)"
VP="${VOID_PACKAGES_DIR:-$HOME/void-packages}"

if [ ! -d "$VP/.git" ]; then
  echo ">> cloning void-packages into $VP"
  git clone https://github.com/void-linux/void-packages.git "$VP"
fi
cd "$VP"

# discord and other restricted templates need this opt-in
grep -q '^XBPS_ALLOW_RESTRICTED=yes' etc/conf 2>/dev/null || echo 'XBPS_ALLOW_RESTRICTED=yes' >> etc/conf

if [ ! -d masterdir ] && [ ! -d "masterdir-$(uname -m)" ]; then
  echo ">> binary-bootstrap (one-time, downloads a base build environment)"
  ./xbps-src binary-bootstrap
fi

grep -vE '^\s*(#|$)' "$REPO/packages-src.txt" | while IFS= read -r pkg; do
  echo ">> building $pkg"
  ./xbps-src pkg "$pkg"
  # built binaries land in hostdir/binpkgs (nonfree ones under .../nonfree)
  sudo xbps-install -y \
    --repository="$VP/hostdir/binpkgs" \
    --repository="$VP/hostdir/binpkgs/nonfree" \
    "$pkg"
done
echo ">> xbps-src packages done"
