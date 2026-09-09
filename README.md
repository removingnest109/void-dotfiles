# Void Linux setup

Reproducible config for my Void Linux (xbps, bspwm/X11) machine — Dell Inspiron i7-1255U.

## What's here

| Path | What |
|------|------|
| `packages.txt` | Manually-installed xbps packages from official repos (bare names) |
| `packages-src.txt` | Packages **not** in the repos, built via xbps-src (discord, runner) |
| `build-src.sh` | Clones void-packages, binary-bootstraps, builds `packages-src.txt` |
| `services.txt` | runit services I enable (base ones like dbus/udevd excluded) |
| `config/` | `~/.config` trees (bspwm, sxhkd, polybar, rofi, alacritty, …), stowed into place |
| `home/` | home dotfiles (`.bashrc`, `.gitconfig`, `.Xresources`, …) |
| `local/` | curated `~/.local` (my `bin/` scripts, `share/applications`, icons) |
| `etc/` | curated `/etc` (xbps mirror config, `tlp.conf`, lightdm) |
| `install.sh` | restore everything onto a machine (idempotent) |
| `sync.sh` | refresh the lists/configs **from** this machine so the repo stays current |
| `build-content.sh` | the curation rules (edit to track more/less); called by `sync.sh` |

## Restore on a NEW laptop

Everything above `install.sh` is scriptable. The steps below it are the manual,
once-per-machine parts a script can't safely do.

### 1. Manual base install (can't be scripted)
1. Boot the Void live ISO.
2. **Disk**: this machine uses LUKS + LVM (and `mdadm` is installed) — recreate your
   partition/crypt/LVM layout by hand. This is the one genuinely non-reproducible step.
3. Run the Void installer (`void-installer`) or a manual `xbps-install -S base-system`
   chroot install onto the LVM volumes.
4. **GRUB (EFI)**: `grub-x86_64-efi` — install to the EFI partition, `grub-mkconfig`.
5. Reboot, log in as your user, `sudo xbps-install -Su` to fully update.

### 2. Scripted restore
```sh
git clone <this repo> ~/dotfiles
cd ~/dotfiles
./install.sh --dry-run   # inspect first
./install.sh             # repo pkgs → xbps-src pkgs → dotfiles → services → /etc
```
`install.sh` calls `build-src.sh` for `discord` and `runner`, which aren't in the
official repos. That step clones `void-packages`, runs a one-time `binary-bootstrap`
(downloads a base build environment — slow), builds each package, and installs it.
`discord` is a *restricted* template (shipped with void-packages), so `build-src.sh`
sets `XBPS_ALLOW_RESTRICTED=yes`. `runner` is my own project: `build-src.sh` clones
`github.com/removingnest109/runner` into `~/Projects/runner` and copies its
`packaging/void/template` into `void-packages/srcpkgs/runner/` before building.
Run it on its own any time with `./build-src.sh`.
If stow reports a conflict, a real file already exists where a symlink should go —
move/delete it and re-run (`install.sh` uses `stow -R`, so re-running is safe).

### 3. Manual follow-ups (secrets & external installers — deliberately NOT in git)
- **Claude Code**: reinstall via its official installer, then `~/.local/bin/claude` relinks.
- **GitHub CLI**: `gh auth login` (token lives in the system keyring, not here).
- **git credentials**: `~/.git-credentials` is gitignored — re-auth as needed.
- **gnome-keyring**: passwords aren't exported; unlock/recreate on first login.
- **VSCode (Code - OSS)**: only `settings.json`/`keybindings.json` are tracked;
  reinstall extensions from within the editor.

## Keeping it current
After installing new software or enabling a service:
```sh
~/dotfiles/sync.sh          # regenerates lists + re-copies configs, shows a diff
git add -A && git commit -m "sync" && git push
```
