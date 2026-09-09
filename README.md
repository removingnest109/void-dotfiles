# Void Linux setup

A bspwm/X11 desktop setup for Void Linux (xbps), reproducible on a fresh install:
packages, runit services, dotfiles, and a few curated `/etc` files, restored by one
idempotent script.

## What's here

| Path | What |
|------|------|
| `packages.txt` | Manually-installed xbps packages from official repos (bare names) |
| `packages-src.txt` | Packages **not** in the repos, built via xbps-src (discord, runner) |
| `packages-musl-skip.txt` | Packages to exclude on a `--musl` install (not in the musl repo) |
| `build-src.sh` | Clones void-packages, binary-bootstraps, builds `packages-src.txt` |
| `services.txt` | runit services to enable (base ones like dbus/udevd excluded) |
| `config/` | `~/.config` trees (bspwm, sxhkd, rofi, alacritty, …), stowed into place |
| `home/` | home dotfiles (`.bashrc`, `.gitconfig`, `.Xresources`, …) |
| `local/` | curated `~/.local` (scripts, `share/applications`, icons) |
| `etc/` | curated `/etc` (xbps mirror config, `tlp.conf`, lightdm) |
| `install.sh` | restore everything onto a machine (idempotent) |
| `sync-packages.sh` | regenerate `packages.txt` + `services.txt` from the current machine |

Configs are **stow-managed**: `~/.config`, home dotfiles and `~/.local` are symlinks
into this repo, so editing them edits the repo directly — no copy step, no drift.

## Install on a fresh Void system

Start from a working Void install (any method — e.g. `void-installer` from the live
ISO). Use a **glibc** system, not musl: `discord` is glibc-only and won't build on musl.
Boot in, make sure you have networking, and update:

```sh
sudo xbps-install -Su
```

Then clone and run:

```sh
sudo xbps-install -S git
git clone https://github.com/removingnest109/void-dotfiles.git ~/void-dotfiles
cd ~/void-dotfiles
./install.sh --dry-run   # inspect what it will do
./install.sh             # repo pkgs → xbps-src pkgs → dotfiles → services → /etc
```

Flags (combinable, any order):
- `--dry-run` — print every step without changing anything.
- `--skip-src` — skip the xbps-src step entirely: no discord/runner, and
  `void-packages` is never cloned or bootstrapped. Handy for a quick install without
  the slow source build.
- `--musl` — install on a **musl** system: points the repo config at the musl subtree
  (`…/current/musl`), excludes the packages listed in `packages-musl-skip.txt`, and
  implies `--skip-src` (discord is glibc-only). If `xbps-install` still fails on a
  "package not found", add that package to `packages-musl-skip.txt` and re-run.

`install.sh` is idempotent — safe to re-run. It runs best **before** starting a
graphical session (an empty `~/.config` means stow has nothing to collide with). If
stow reports a conflict, a real file already exists where a symlink should go — move or
delete it and re-run (`install.sh` uses `stow -R`, so re-running is safe).

### xbps-src packages (discord + runner)

`install.sh` calls `build-src.sh` for the packages that aren't in the official repos.
That step clones `void-packages`, runs a one-time `binary-bootstrap` (downloads a base
build environment — slow), then builds and installs each:

- **discord** — a *restricted* template shipped with void-packages, so `build-src.sh`
  sets `XBPS_ALLOW_RESTRICTED=yes`.
- **runner** — built from its own template: `build-src.sh` clones
  `github.com/removingnest109/runner` into `~/Projects/runner` and copies its
  `packaging/void/template` into `void-packages/srcpkgs/runner/` before building.

Run it on its own any time with `./build-src.sh`.

## Keeping it current

**Editing a tracked config** — just edit it in place (e.g. `~/.config/bspwm/bspwmrc`);
it's a symlink into this repo, so the change is already here. Then:
```sh
git -C ~/void-dotfiles add -A && git -C ~/void-dotfiles commit -m "tweak" && git -C ~/void-dotfiles push
```

**After installing a package or enabling a service** — regenerate the manifests:
```sh
~/void-dotfiles/sync-packages.sh # rewrites packages.txt + services.txt, shows a diff
git -C ~/void-dotfiles add -A && git -C ~/void-dotfiles commit -m "sync" && git -C ~/void-dotfiles push
```

**Tracking a NEW config file** — move it into the repo, then stow it back as a symlink:
```sh
mv ~/.config/foo ~/void-dotfiles/config/.config/foo
stow --no-folding -R -t ~ -d ~/void-dotfiles config
git -C ~/void-dotfiles add -A && git -C ~/void-dotfiles commit -m "track foo"
```

**A self-built (xbps-src) package** — add its name to `packages-src.txt` by hand
(`sync-packages.sh` keeps `packages.txt` and `packages-src.txt` from overlapping).
