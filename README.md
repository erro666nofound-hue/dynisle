# dynisle

A single "dynamic island" shell for Hyprland on Arch Linux, written in
[Quickshell](https://quickshell.org). One floating pill at the top of the
screen that grows into whatever you need: launcher, control centre, media,
notifications, wallpaper picker, session menu, screenshots.

## Install on a fresh Arch

1. Install Arch (`archinstall` with the *minimal* profile is enough) and log in.
2. Get `git`, clone this repo into place, and run the installer:

   ```sh
   sudo pacman -S --needed git
   git clone <this repo's URL> ~/.config/quickshell/dynisle
   ~/.config/quickshell/dynisle/install.sh
   ```

3. Reboot and log in on the tuigreet screen.

`install.sh` only uses Arch's official repositories - no AUR helper. It backs
up anything it replaces in `~/.config` to `~/.config/dynisle-backup-<date>/`.
Try `./install.sh --dry-run` first to see every step without changing
anything.

## Keeping the repo in step with your machine

The configs in `dots/` are a copy. After changing things on your machine:

```sh
cd ~/.config/quickshell/dynisle
./install.sh --collect      # copy ~/.config -> dots/
git add -A && git commit -m "update configs" && git push
```

## Keys

| | |
|---|---|
| `SUPER` + `D` | launcher |
| `SUPER` + `R` | control centre |
| `SUPER` + `A` | wallpaper and colours |
| `SUPER` + `S` | lock, sleep, restart, shut down |
| `Shift` + `Print` / `SUPER` + `Print` | screenshot a region / the whole screen |
| `SUPER` + `Space` | Vietnamese typing on/off |

## What is where

| | |
|---|---|
| `shell.qml`, `modules/`, `services/` | the shell |
| `dots/` | Hyprland, hypridle, hyprlock, matugen, kitty, foot, fish, fuzzel, fcitx5, fastfetch |
| `system/` | power-plan helper + polkit rule, greetd config, session launcher |
| `fonts/` | Google Sans Flex |
| `vault/` | design notes and the build history |

## Credits

- The Hyprland config in `dots/hypr/hyprland/` started from
  [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) (GPL-3.0).
- Google Sans Flex: SIL Open Font License (`fonts/GoogleSansFlex-LICENSE.txt`).
